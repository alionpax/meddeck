import express from "express";
import { Storage } from "@google-cloud/storage";
import { execFile } from "child_process";
import fs from "fs";
import path from "path";

const app = express();
app.use(express.json());

const storage = new Storage();

const WORK_DIR = "/tmp/work";
const INPUT_PPTX = "input.pptx";
const OUTPUT_PDF = "slides.pdf";
const OUTPUT_DIR = "out";

app.post("/convert", async (req, res) => {
  const { bucket, filePath } = req.body;

  if (!bucket || !filePath) {
    return res.status(400).json({
      error: "bucket_and_filePath_required"
    });
  }

  try {
    // Reset work dir
    fs.rmSync(WORK_DIR, { recursive: true, force: true });
    fs.mkdirSync(WORK_DIR, { recursive: true });

    const pptxPath = path.join(WORK_DIR, INPUT_PPTX);
    const pdfPath = path.join(WORK_DIR, OUTPUT_PDF);
    const outputPath = path.join(WORK_DIR, OUTPUT_DIR);

    fs.mkdirSync(outputPath, { recursive: true });

    // 1️⃣ Download PPTX
    await storage
      .bucket(bucket)
      .file(filePath)
      .download({ destination: pptxPath });

    // 2️⃣ PPTX → PDF (Impress)
    await new Promise((resolve, reject) => {
      execFile(
        "libreoffice",
        [
          "--headless",
          "--infilter=impress8",
          "--convert-to",
          "pdf:impress_pdf_Export",
          "--outdir",
          WORK_DIR,
          pptxPath
        ],
        (err) => (err ? reject(err) : resolve())
      );
    });

    if (!fs.existsSync(pdfPath)) {
      throw new Error("PDF export failed");
    }

    // 3️⃣ PDF → PNG (Draw)
    await new Promise((resolve, reject) => {
      execFile(
        "libreoffice",
        [
          "--headless",
          "--convert-to",
          "png",
          "--outdir",
          outputPath,
          pdfPath
        ],
        (err) => (err ? reject(err) : resolve())
      );
    });

    // 4️⃣ Collect PNGs
    const files = fs
      .readdirSync(outputPath)
      .filter((f) => f.endsWith(".png"))
      .sort();

    if (files.length === 0) {
      throw new Error("PDF to PNG conversion produced no images");
    }

    // 5️⃣ Upload slides
    const uploadedSlides = [];

    for (const file of files) {
      const localFile = path.join(outputPath, file);
      const destination = `${filePath}/slides/${file}`;

      await storage.bucket(bucket).upload(localFile, {
        destination,
        contentType: "image/png"
      });

      uploadedSlides.push(destination);
    }

    res.json({
      status: "ok",
      slideCount: uploadedSlides.length,
      slides: uploadedSlides
    });
  } catch (err) {
    console.error("Conversion failed:", err);
    res.status(500).json({
      error: "conversion_failed",
      message: err.message
    });
  }
});

app.post("/health", (_, res) => {
  res.json({ status: "ok" });
});

app.listen(process.env.PORT, () => {
  console.log("MedDeck PPT converter running (PDF pipeline)");
});
