import express from "express";
import { Storage } from "@google-cloud/storage";
import { execFile } from "child_process";
import fs from "fs";
import os from "os";
import path from "path";

const app = express();
app.use(express.json()); // ✅ MUST be express.json()

const storage = new Storage();

function runLibreOffice(args, timeoutMs = 240000) {
  return new Promise((resolve, reject) => {
    execFile("libreoffice", args, { timeout: timeoutMs }, (err, stdout, stderr) => {
      if (err) {
        err.stdout = stdout;
        err.stderr = stderr;
        return reject(err);
      }
      resolve({ stdout, stderr });
    });
  });
}

app.post("/convert", async (req, res) => {
  const { bucket, filePath } = req.body ?? {};

  if (!bucket || !filePath) {
    return res.status(400).json({
      error: "bucket_and_filePath_required"
    });
  }

  // ✅ Unique work dir per request
  const workDir = fs.mkdtempSync(path.join(os.tmpdir(), "meddeck-"));
  const pptxPath = path.join(workDir, "input.pptx");
  const pngOutDir = path.join(workDir, "out");
  const loProfileDir = path.join(workDir, "lo-profile");

  // LibreOffice wants a file:// URI for UserInstallation
  const loProfileUri = `file://${loProfileDir.replace(/\\/g, "/")}`;

  try {
    fs.mkdirSync(pngOutDir, { recursive: true });
    fs.mkdirSync(loProfileDir, { recursive: true });

    // 1) Download PPTX from Storage
    await storage.bucket(bucket).file(filePath).download({ destination: pptxPath });

    // 2) PPTX → PDF (don’t assume output name)
    try {
      await runLibreOffice([
        "--headless",
        "--nologo",
        "--nolockcheck",
        `-env:UserInstallation=${loProfileUri}`,
        "--convert-to",
        "pdf",
        "--outdir",
        workDir,
        pptxPath
      ]);
    } catch (e) {
      const files = safeListDir(workDir);
      return res.status(500).json({
        error: "conversion_failed",
        message: "LibreOffice PPTX→PDF step failed",
        details: {
          workDirFiles: files,
          stdout: e.stdout,
          stderr: e.stderr
        }
      });
    }

    const workFilesAfterPdf = safeListDir(workDir);
    const pdfFiles = workFilesAfterPdf.filter((f) => f.toLowerCase().endsWith(".pdf"));

    if (pdfFiles.length === 0) {
      return res.status(500).json({
        error: "conversion_failed",
        message: "LibreOffice did not generate a PDF",
        details: { workDirFiles: workFilesAfterPdf }
      });
    }

    const pdfPath = path.join(workDir, pdfFiles[0]);

    // 3) PDF → PNG
    try {
      await runLibreOffice([
        "--headless",
        "--nologo",
        "--nolockcheck",
        `-env:UserInstallation=${loProfileUri}`,
        "--convert-to",
        "png",
        "--outdir",
        pngOutDir,
        pdfPath
      ]);
    } catch (e) {
      const files = safeListDir(workDir);
      const pngFiles = safeListDir(pngOutDir);
      return res.status(500).json({
        error: "conversion_failed",
        message: "LibreOffice PDF→PNG step failed",
        details: {
          workDirFiles: files,
          outDirFiles: pngFiles,
          stdout: e.stdout,
          stderr: e.stderr
        }
      });
    }

    // 4) Collect PNGs
    const pngFiles = safeListDir(pngOutDir)
      .filter((f) => f.toLowerCase().endsWith(".png"))
      .sort();

    if (pngFiles.length === 0) {
      return res.status(500).json({
        error: "conversion_failed",
        message: "PDF to PNG conversion produced no images",
        details: {
          workDirFiles: safeListDir(workDir),
          outDirFiles: safeListDir(pngOutDir)
        }
      });
    }

    // 5) Upload PNGs back to Storage
    const uploadedSlides = [];
    for (const file of pngFiles) {
      const localFile = path.join(pngOutDir, file);
      const destination = `${filePath}/slides/${file}`;

      await storage.bucket(bucket).upload(localFile, {
        destination,
        contentType: "image/png"
      });

      uploadedSlides.push(destination);
    }

    return res.json({
      status: "ok",
      slideCount: uploadedSlides.length,
      slides: uploadedSlides
    });
  } catch (err) {
    console.error("Conversion failed:", err);
    return res.status(500).json({
      error: "conversion_failed",
      message: err?.message ?? String(err)
    });
  } finally {
    // Best-effort cleanup
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

function safeListDir(dirPath) {
  try {
    return fs.readdirSync(dirPath);
  } catch {
    return [];
  }
}
