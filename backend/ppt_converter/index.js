import express from "express";
import { Storage } from "@google-cloud/storage";
import { Firestore } from "@google-cloud/firestore";
import { execFile } from "child_process";
import fs from "fs";
import path from "path";

const app = express();
app.use(express.json());

const storage = new Storage();
const firestore = new Firestore();

const WORK_DIR = "/tmp/work";
const INPUT_PPTX = "input.pptx";
const OUTPUT_DIR = "out";

// ---------- helpers ----------
function execFileAsync(cmd, args, opts = {}) {
  return new Promise((resolve, reject) => {
    execFile(cmd, args, opts, (err, stdout, stderr) => {
      if (err) {
        const e = new Error(`${cmd} failed: ${err.message}`);
        e.stdout = stdout?.toString?.() ?? "";
        e.stderr = stderr?.toString?.() ?? "";
        return reject(e);
      }
      resolve({ stdout: stdout?.toString?.() ?? "", stderr: stderr?.toString?.() ?? "" });
    });
  });
}

function listFilesSafe(dir) {
  try {
    return fs.readdirSync(dir);
  } catch {
    return [];
  }
}

async function findDeckDocIdByPptPath(filePath) {
  const snap = await firestore
    .collection("decks")
    .where("pptPath", "==", filePath)
    .limit(1)
    .get();

  if (snap.empty) return null;
  return snap.docs[0].id;
}

app.get("/health", (req, res) => res.json({ status: "ok" }));

app.get("/diag", async (req, res) => {
  const pdftoppmPath = fs.existsSync("/usr/bin/pdftoppm") ? "/usr/bin/pdftoppm" : null;
  res.json({
    status: "ok",
    pdftoppmPath,
  });
});

app.post("/convert", async (req, res) => {
  const { bucket, filePath, deckId: deckIdFromBody } = req.body;

  if (!bucket || !filePath) {
    return res.status(400).json({ error: "bucket_and_filePath_required" });
  }

  try {
    // Reset workspace
    fs.rmSync(WORK_DIR, { recursive: true, force: true });
    fs.mkdirSync(WORK_DIR, { recursive: true });

    const pptxPath = path.join(WORK_DIR, INPUT_PPTX);
    const pngOutDir = path.join(WORK_DIR, OUTPUT_DIR);
    fs.mkdirSync(pngOutDir, { recursive: true });

    // 1) Download PPTX
    await storage.bucket(bucket).file(filePath).download({ destination: pptxPath });

    // 2) PPTX -> PDF (LibreOffice)
    // Use a dedicated profile dir to avoid first-run issues
    const loProfileDir = path.join(WORK_DIR, "lo-profile");
    fs.mkdirSync(loProfileDir, { recursive: true });

    await execFileAsync("libreoffice", [
      "--headless",
      "--nologo",
      "--nolockcheck",
      `-env:UserInstallation=file://${loProfileDir}`,
      "--convert-to",
      "pdf",
      "--outdir",
      WORK_DIR,
      pptxPath,
    ]);

    // Find produced PDF
    const pdfFiles = listFilesSafe(WORK_DIR).filter((f) => f.toLowerCase().endsWith(".pdf"));
    if (pdfFiles.length === 0) {
      throw new Error("LibreOffice did not generate a PDF");
    }
    // In case multiple PDFs exist, pick the newest
    const pdfPath = path.join(WORK_DIR, pdfFiles[0]);

    // 3) PDF -> PNGs (pdftoppm)
    // Produces files like slide_001.png, slide_002.png...
    const outPrefix = path.join(pngOutDir, "slide");
    await execFileAsync("pdftoppm", [
      "-png",
      "-r",
      "150",
      pdfPath,
      outPrefix,
    ]);

    // Collect PNGs
    const pngFiles = listFilesSafe(pngOutDir)
      .filter((f) => f.toLowerCase().endsWith(".png"))
      .sort();

    if (pngFiles.length === 0) {
      throw new Error("PDF to PNG produced no images");
    }

    // Rename to slide_001.png format (pdftoppm makes slide-1.png sometimes depending on args)
    // With our prefix usage, it will be slide-1.png style. Normalize:
    const normalized = [];
    for (const f of pngFiles) {
      // pdftoppm outputs slide-1.png, slide-2.png, ...
      const m = f.match(/slide-(\d+)\.png$/i);
      if (m) {
        const n = parseInt(m[1], 10);
        const newName = `slide_${String(n).padStart(3, "0")}.png`;
        fs.renameSync(path.join(pngOutDir, f), path.join(pngOutDir, newName));
        normalized.push(newName);
      } else {
        normalized.push(f);
      }
    }

    const slidePngs = listFilesSafe(pngOutDir)
      .filter((f) => f.toLowerCase().endsWith(".png"))
      .sort();

    // 4) Upload slides + generate signed URLs
    const uploadedPaths = [];
    const signedUrls = [];

    for (const file of slidePngs) {
      const localFile = path.join(pngOutDir, file);
      const destination = `${filePath}/slides/${file}`;

      await storage.bucket(bucket).upload(localFile, {
        destination,
        contentType: "image/png",
      });

      uploadedPaths.push(destination);

      const [url] = await storage.bucket(bucket).file(destination).getSignedUrl({
        action: "read",
        expires: "03-01-2035", // long-lived
      });

      signedUrls.push(url);
    }

    const coverPath = uploadedPaths[0];
    const coverUrl = signedUrls[0];

    // 5) Update Firestore deck doc (write BOTH: paths + URLs)
    const deckId = deckIdFromBody ?? (await findDeckDocIdByPptPath(filePath));
    if (deckId) {
      await firestore.collection("decks").doc(deckId).set(
        {
          pptPath: filePath,
          bucket,
          conversionStatus: "done",
          conversionError: null,
          convertedAt: new Date(),

          // Path-based fields (your new pipeline)
          slides: uploadedPaths,
          coverSlide: coverPath,

          // URL-based fields (for your existing UI)
          slideImageUrls: signedUrls,
          coverImageUrl: coverUrl,
          slideCount: signedUrls.length,
        },
        { merge: true }
      );
    }

    res.json({
      status: "ok",
      slideCount: signedUrls.length,
      pdfPages: signedUrls.length, // approximate; you can compute separately if you want
      slides: uploadedPaths,
      slideImageUrls: signedUrls,
      coverSlide: coverPath,
      coverImageUrl: coverUrl,
      deckId: deckId ?? null,
    });
  } catch (err) {
    console.error("Conversion failed:", err);

    res.status(500).json({
      error: "conversion_failed",
      message: err.message,
      details: {
        stdout: err.stdout ?? "",
        stderr: err.stderr ?? "",
        workDirFiles: listFilesSafe(WORK_DIR),
        outDirFiles: listFilesSafe(path.join(WORK_DIR, OUTPUT_DIR)),
      },
    });
  }
});

app.listen(process.env.PORT || 8080, () => {
  console.log("MedDeck PPT converter running");
});
