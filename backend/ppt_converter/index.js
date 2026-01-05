import express from "express";
import { Storage } from "@google-cloud/storage";
import { execFile } from "child_process";
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
  // pdfinfo output includes: "Pages:          4"
  const m = pdfInfoStdout.match(/Pages:\s+(\d+)/);
  return m ? Number(m[1]) : null;
}

function numericPageSort(a, b) {
  // slide-1.png, slide-2.png, ...
  const na = Number((a.match(/-(\d+)\.png$/i) || [])[1] ?? 0);
  const nb = Number((b.match(/-(\d+)\.png$/i) || [])[1] ?? 0);
  return na - nb;
}

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

    // 2) PPTX -> PDF (LibreOffice)
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

    // Find generated PDF (don’t assume name)
    const workFiles = safeListDir(workDir);
    const pdfFiles = workFiles.filter((f) => f.toLowerCase().endsWith(".pdf"));
    if (pdfFiles.length === 0) {
      return res.status(500).json({
        error: "conversion_failed",
        message: "LibreOffice did not generate a PDF",
        details: { workDirFiles: workFiles }
      });
    }

    // Choose most recently modified PDF (handles weird naming)
    const pdfPath = pdfFiles
      .map((name) => ({ name, full: path.join(workDir, name) }))
      .sort((a, b) => fs.statSync(b.full).mtimeMs - fs.statSync(a.full).mtimeMs)[0].full;

    // 2.5) Inspect PDF page count (Poppler)
    let pdfPages = null;
    try {
      const info = await runCmd("pdfinfo", [pdfPath], 60000);
      pdfPages = parsePdfPages(info.stdout);
    } catch {
      // Not fatal; conversion can proceed
    }

    // 3) PDF -> PNG pages (Poppler pdftoppm) ✅ reliable multi-page output
    // Output files: slide-1.png, slide-2.png, ...
    const prefix = path.join(pngOutDir, "slide");
    await runCmd("pdftoppm", [
      "-png",
      "-r",
      "150",
      pdfPath,
      prefix
    ]);

    const pngFiles = safeListDir(pngOutDir)
      .filter((f) => /^slide-\d+\.png$/i.test(f))
      .sort(numericPageSort);

    if (pngFiles.length === 0) {
      return res.status(500).json({
        error: "conversion_failed",
        message: "pdftoppm produced no PNG files",
        details: { workDirFiles: safeListDir(workDir), outDirFiles: safeListDir(pngOutDir) }
      });
    }

    // 4) Upload slides with nice ordered names (slide_001.png ...)
    const uploadedSlides = [];
    for (let i = 0; i < pngFiles.length; i++) {
      const file = pngFiles[i];
      const localFile = path.join(pngOutDir, file);

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
        stdout: err?.stdout,
        stderr: err?.stderr
      }
    });
  } finally {
    try {
      fs.rmSync(workDir, { recursive: true, force: true });
    } catch {}
  }
});

app.post("/health", (_, res) => res.json({ status: "ok" }));

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`MedDeck PPT converter running on port ${PORT}`);
});
