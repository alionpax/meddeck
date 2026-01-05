import express from "express";
import { Storage } from "@google-cloud/storage";
import { execFile, execFileSync } from "child_process";
import fs from "fs";
import os from "os";
import path from "path";

const app = express();
app.use(express.json());

const storage = new Storage();

function safeListDir(dirPath) {
  try {
    return fs.readdirSync(dirPath);
  } catch {
    return [];
  }
}

function runCmd(bin, args, timeoutMs = 300000) {
  return new Promise((resolve, reject) => {
    execFile(bin, args, { timeout: timeoutMs }, (err, stdout, stderr) => {
      if (err) {
        err.stdout = stdout;
        err.stderr = stderr;
        return reject(err);
      }
      resolve({ stdout, stderr });
    });
  });
}

function parsePdfPages(pdfInfoStdout) {
  const m = pdfInfoStdout.match(/Pages:\s+(\d+)/);
  return m ? Number(m[1]) : null;
}

function numericPageSort(a, b) {
  const na = Number((a.match(/-(\d+)\.png$/i) || [])[1] ?? 0);
  const nb = Number((b.match(/-(\d+)\.png$/i) || [])[1] ?? 0);
  return na - nb;
}

app.get("/health", (_, res) => res.json({ status: "ok" }));

// Quick check that pdftoppm exists in the running container
app.get("/healthz", (_, res) => {
  try {
    execFileSync("pdftoppm", ["-h"], { stdio: "ignore" });
    res.json({ status: "ok", pdftoppm: "present" });
  } catch {
    res.status(500).json({ status: "bad", pdftoppm: "missing" });
  }
});

// More detailed diagnostics (path + help header)
app.get("/diag", async (_, res) => {
  try {
    const { stdout: whichOut } = await runCmd("sh", ["-lc", "command -v pdftoppm"], 10000);
    const { stdout: helpOut } = await runCmd("sh", ["-lc", "pdftoppm -h | head -n 1"], 10000);
    res.json({
      status: "ok",
      pdftoppmPath: whichOut.trim(),
      pdftoppmHelp: helpOut.trim()
    });
  } catch (e) {
    res.status(500).json({
      status: "bad",
      message: e?.message ?? String(e),
      details: { stdout: e?.stdout ?? "", stderr: e?.stderr ?? "" }
    });
  }
});

app.post("/convert", async (req, res) => {
  const { bucket, filePath } = req.body ?? {};
  if (!bucket || !filePath) {
    return res.status(400).json({ error: "bucket_and_filePath_required" });
  }

  const workDir = fs.mkdtempSync(path.join(os.tmpdir(), "meddeck-"));
  const pptxPath = path.join(workDir, "input.pptx");
  const pngOutDir = path.join(workDir, "out");
  const loProfileDir = path.join(workDir, "lo-profile");
  const loProfileUri = `file://${loProfileDir.replace(/\\/g, "/")}`;

  try {
    fs.mkdirSync(pngOutDir, { recursive: true });
    fs.mkdirSync(loProfileDir, { recursive: true });

    // 1) Download PPTX
    await storage.bucket(bucket).file(filePath).download({ destination: pptxPath });

    // 2) PPTX → PDF (LibreOffice)
    await runCmd("libreoffice", [
      "--headless",
      "--nologo",
      "--nolockcheck",
      `-env:UserInstallation=${loProfileUri}`,
      "--convert-to",
      "pdf:impress_pdf_Export",
      "--outdir",
      workDir,
      pptxPath
    ]);

    const workFilesAfterPdf = safeListDir(workDir);
    const pdfFiles = workFilesAfterPdf.filter((f) => f.toLowerCase().endsWith(".pdf"));
    if (pdfFiles.length === 0) {
      return res.status(500).json({
        error: "conversion_failed",
        message: "LibreOffice did not generate a PDF",
        details: { workDirFiles: workFilesAfterPdf }
      });
    }

    // Choose most recently modified PDF (handles odd naming)
    const pdfPath = pdfFiles
      .map((name) => ({ name, full: path.join(workDir, name) }))
      .sort((a, b) => fs.statSync(b.full).mtimeMs - fs.statSync(a.full).mtimeMs)[0].full;

    // (Optional) PDF page count
    let pdfPages = null;
    try {
      const info = await runCmd("pdfinfo", [pdfPath], 60000);
      pdfPages = parsePdfPages(info.stdout);
    } catch {
      // not fatal
    }

    // 3) PDF → PNG (Poppler pdftoppm)
    // Output: slide-1.png, slide-2.png, ...
    const prefix = path.join(pngOutDir, "slide");
    await runCmd("pdftoppm", ["-png", "-r", "150", pdfPath, prefix], 300000);

    const pngFiles = safeListDir(pngOutDir)
      .filter((f) => /^slide-\d+\.png$/i.test(f))
      .sort(numericPageSort);

    if (pngFiles.length === 0) {
      return res.status(500).json({
        error: "conversion_failed",
        message: "pdftoppm produced no PNG files",
        details: {
          pdfPages,
          workDirFiles: safeListDir(workDir),
          outDirFiles: safeListDir(pngOutDir)
        }
      });
    }

    // 4) Upload slides with stable names slide_001.png ...
    const uploadedSlides = [];
    for (let i = 0; i < pngFiles.length; i++) {
      const localFile = path.join(pngOutDir, pngFiles[i]);
      const pageNum = String(i + 1).padStart(3, "0");
      const destName = `slide_${pageNum}.png`;
      const destination = `${filePath}/slides/${destName}`;

      await storage.bucket(bucket).upload(localFile, {
        destination,
        contentType: "image/png"
      });

      uploadedSlides.push(destination);
    }

    return res.json({
      status: "ok",
      pdfPages,
      slideCount: uploadedSlides.length,
      slides: uploadedSlides
    });
  } catch (err) {
    console.error("Conversion failed:", err);
    return res.status(500).json({
      error: "conversion_failed",
      message: err?.message ?? String(err),
      details: {
        stdout: err?.stdout ?? "",
        stderr: err?.stderr ?? "",
        workDirFiles: safeListDir(workDir),
        outDirFiles: safeListDir(pngOutDir)
      }
    });
  } finally {
    try {
      fs.rmSync(workDir, { recursive: true, force: true });
    } catch {}
  }
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`MedDeck PPT converter running on port ${PORT}`);
});
