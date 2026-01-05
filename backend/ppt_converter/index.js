import express from "express";
import { Storage } from "@google-cloud/storage";
import { execFile } from "child_process";
import fs from "fs";
import path from "path";

const app = express();
app.use(express.json());

const storage = new Storage();

const WORK_DIR = "/tmp/work";
const INPUT_FILE = "input.pptx";
const OUTPUT_DIR = "out";

app.post("/convert", async (req, res) => {
  const { bucket, filePath } = req.body;

  if (!bucket || !filePath) {
    return res.status(400).json({
      error: "bucket_and_filePath_required"
    });
  }

  try {
    // Clean and prepare working directories
    fs.rmSync(WORK_DIR, { recursive: true, force: true });
    fs.mkdirSync(path.join(WORK_DIR, OUTPUT_DIR), { recursive: true });

    const inputPath = path.join(WORK_DIR, INPUT_FILE);
    const outputPath = path.join(WORK_DIR, OUTPUT_DIR);

    // Download PPTX from Firebase Storage
    await storage
      .bucket(bucket)
      .file(filePath)
      .download({ destination: inputPath });

    // Convert ALL slides using LibreOffice Impress PNG export
    await new Promise((resolve, reject) => {
      execFile(
        "libreoffice",
        [
          "--headless",
          "--convert-to",
          "png:impress_png_Export",
          "--outdir",
          outputPath,
          inputPath
        ],
        (error) => {
          if (error) reject(error);
          else resolve();
        }
      );
    });

    // Read and upload generated slides
    const files = fs
      .readdirSync(outputPath)
      .filter((f) => f.endsWith(".png"))
      .sort();

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
  console.log("MedDeck PPT converter running");
});
