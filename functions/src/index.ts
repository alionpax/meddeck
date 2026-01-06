import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";
import * as admin from "firebase-admin";
import { GoogleAuth } from "google-auth-library";

admin.initializeApp();

const REGION = "us-central1";
const CONVERTER_URL =
  "https://meddeck-ppt-converter-52591950022.us-central1.run.app/convert";

const SIGNED_URL_EXPIRES = "2035-03-01";

export const onDeckApproved = onDocumentUpdated(
  {
    document: "decks/{deckId}",
    region: REGION,
    retry: true,
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const deckId = event.params.deckId;

    if (!before || !after) return;

    // Only run when status transitions -> approved
    if (after.status !== "approved" || before.status === "approved") return;

    // ✅ Idempotency: if URLs already exist, skip
    if (Array.isArray(after.slideImageUrls) && after.slideImageUrls.length > 0) {
      logger.info("slideImageUrls already exist, skipping conversion", { deckId });
      return;
    }

    const bucketName =
      (after.bucket as string) || "meddeck-4cb95.firebasestorage.app";

    // Prefer explicit pptPath stored on doc
    let pptPath: string | null = (after.pptPath as string) || null;

    // Fallback: find first ppt/pptx under ppts/{deckId}
    if (!pptPath) {
      const storageBucket = admin.storage().bucket(bucketName);
      const prefix = `ppts/${deckId}`;
      const [files] = await storageBucket.getFiles({ prefix });

      const ppt =
        files.find((f) => f.name.toLowerCase().endsWith(".pptx")) ||
        files.find((f) => f.name.toLowerCase().endsWith(".ppt"));

      if (!ppt) {
        logger.error("No PPT/PPTX found for deck", { deckId, prefix, bucketName });
        await admin.firestore().doc(`decks/${deckId}`).update({
          conversionStatus: "error",
          conversionError: `No PPT/PPTX found in Storage under ${prefix}`,
        });
        return;
      }

      pptPath = ppt.name;
    }

    // Mark converting
    await admin.firestore().doc(`decks/${deckId}`).update({
      conversionStatus: "converting",
      conversionError: null,
      convertedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    try {
      // Call Cloud Run with ID token (Cloud Run requires auth)
      const auth = new GoogleAuth();
      const client = await auth.getIdTokenClient(CONVERTER_URL);

      const resp = await client.request({
        url: CONVERTER_URL,
        method: "POST",
        data: { bucket: bucketName, filePath: pptPath },
      });

      const data = resp.data as any;

      if (!data || data.status !== "ok") {
        throw new Error(`Converter returned non-ok: ${JSON.stringify(data)}`);
      }

      const pdfPages: number | null =
        typeof data.pdfPages === "number" ? data.pdfPages : null;

      // Cloud Run currently returns storage paths in `slides`
      const slides: string[] = Array.isArray(data.slides)
        ? data.slides.map((x: any) => String(x))
        : [];

      if (slides.length === 0) {
        throw new Error("Converter returned ok but produced no slides paths");
      }

      // ✅ Convert storage paths -> signed URLs
      const storageBucket = admin.storage().bucket(bucketName);

      const slideImageUrls: string[] = [];
      for (const p of slides) {
        const [url] = await storageBucket.file(p).getSignedUrl({
          action: "read",
          expires: SIGNED_URL_EXPIRES,
        });
        slideImageUrls.push(url);
      }

      if (slideImageUrls.length === 0) {
        throw new Error("Failed to generate signed URLs for slides");
      }

      // ✅ URL-only writeback
      await admin.firestore().doc(`decks/${deckId}`).update({
        slideImageUrls,
        coverImageUrl: slideImageUrls[0] ?? "",
        slideCount: slideImageUrls.length,
        pdfPages,

        conversionStatus: "done",
        conversionError: null,
        convertedAt: admin.firestore.FieldValue.serverTimestamp(),

        // ✅ delete legacy fields so your DB stays clean
        slides: admin.firestore.FieldValue.delete(),
        coverSlide: admin.firestore.FieldValue.delete(),
      });

      logger.info("Deck conversion complete (URL-only)", {
        deckId,
        slideCount: slideImageUrls.length,
        pdfPages,
      });
    } catch (err: any) {
      logger.error("Deck conversion failed", {
        deckId,
        message: err?.message ?? String(err),
      });

      await admin.firestore().doc(`decks/${deckId}`).update({
        conversionStatus: "error",
        conversionError: err?.message ?? String(err),
      });

      throw err; // allow retry
    }
  }
);
