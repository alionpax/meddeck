import express from "express";
import { Storage } from "@google-cloud/storage";
import { execFile } from "child_process";
import fs from "fs";
import os from "os";
import path from "path";

const app = express();
app.use(express.json()); // ✅ IMPORTANT: must be express.json()

const storage = new Storage();

function runLibreOffice(args) {
  return new Promise((resolve, reject) => {
    execFile("libreoffice", args, (err) => (err ? reject(err) : resolve()));
  });
}

app.post("/convert", async (req, res) => {
  const { bucket, filePath } = req.body ?? {};

  if (!bucket || !filePath) {
    return res.status(400).json({ error: "bucket_and_filePath_required" });
  }

  // ✅ Unique work dir per request (prevents concurrency collisions)
  const workDir = fs.mkdtempSync(path.join(os.tmpdir(), "meddeck-"));
  const pptxPath = path.join(workDir, "input.pptx");
  const pngOutDir = path.join(workDir, "out");

  try {
    fs.mkdirSync(pngOutDir, { recursive: true });

    // 1) Download PPTX
    await storage.bucket(bucket).file(filePath).download({ destination: pptxPath });

    // 2) PPTX → PDF (don’t assume PDF filename)
    await runLibreOffice([
      "--headless",
      "--nologo",
      "--nolockcheck",
      "--infilter=impress8",
      "--convert-to",
      "pdf:impress_pdf_Export",
      "--outdir",
      workDir,
      pptxPath
    ]);

    const pdfFiles = fs.readdirSync(workDir).filter((f) => f.toLowerCase().endsWith(".pdf"));
    if (pdfFiles.length === 0) {
      throw new Error("LibreOffice did not generate a PDF");
    }
    const pdfPath = path.join(workDir, pdfFiles[0]);

    // 3) PDF → PNG (one image per page/slide)
    await runLibreOffice([
      "--headless",
      "--nologo",
      "--nolockcheck",
      "--convert-to",
      "png",
      "--outdir",
      pngOutDir,
      pdfPath
    ]);

    // 4) Collect PNGs
    const pngFiles = fs
      .readdirSync(pngOutDir)
      .filter((f) => f.toLowerCase().endsWith(".png"))
      .sort();

    if (pngFiles.length === 0) {
      throw new Error("PDF to PNG conversion produced no images");
    }

    // 5) Upload PNGs
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
