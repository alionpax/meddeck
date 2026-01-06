import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { GoogleAuth } from "google-auth-library";

initializeApp();
const db = getFirestore();

/**
 * 🔧 CONFIG: update these to match your Firestore + Cloud Run setup
 */
const REGION = "us-central1";
const DECKS_COLLECTION = "decks";

// Cloud Run URL (locked behind auth now)
const CONVERTER_URL =
  "https://meddeck-ppt-converter-52591950022.us-central1.run.app/convert";

/**
 * 🔧 CONFIG: field names in your deck doc
 * - statusField: the approval field you already use (e.g. "status")
 * - approvedValue: the value that means "approved" (e.g. "approved")
 * - bucketField: where you store the bucket name (recommended)
 * - filePathField: where you store the Storage path to the pptx (recommended)
 */
const statusField = "status";
const approvedValue = "approved";
const bucketField = "bucket"; // e.g. "meddeck-4cb95.firebasestorage.app"
const filePathField = "pptPath"; // e.g. "ppts/<uid>/<name>.pptx"

// Where we store results back into the same deck document
const slidesField = "slides";
const slideCountField = "slideCount";
const pdfPagesField = "pdfPages";
const convertedAtField = "convertedAt";
const conversionStatusField = "conversionStatus";
const conversionErrorField = "conversionError";

/**
 * Converts a deck when its status transitions -> approved.
 * Idempotent: if slides already exist, it skips.
 */
export const convertDeckOnApprove = onDocumentUpdated(
  {
    document: `${DECKS_COLLECTION}/{deckId}`,
    region: REGION,
    // Optional: retry transient failures automatically
    retry: true
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const deckId = event.params.deckId;

    if (!before || !after) return;

    const beforeStatus = before[statusField];
    const afterStatus = after[statusField];

    // Only run on transition to approved
    if (afterStatus !== approvedValue || beforeStatus === approvedValue) {
      return;
    }

    // Idempotency: if slides already exist, don't reconvert
    const existingSlides = after[slidesField];
    if (Array.isArray(existingSlides) && existingSlides.length > 0) {
      logger.info("Slides already exist, skipping conversion", { deckId });
      return;
    }

    const bucket = after[bucketField];
    const filePath = after[filePathField];

    if (!bucket || !filePath) {
      logger.error("Missing bucket/filePath on deck doc", { deckId, bucket, filePath });
      await db.collection(DECKS_COLLECTION).doc(deckId).update({
        [conversionStatusField]: "error",
        [conversionErrorField]: "Missing bucket or pptPath on deck document"
      });
      return;
    }

    logger.info("Starting conversion", { deckId, bucket, filePath });

    // Mark as converting
    await db.collection(DECKS_COLLECTION).doc(deckId).update({
      [conversionStatusField]: "converting",
      [conversionErrorField]: null
    });

    try {
      /**
       * Cloud Run auth: google-auth-library will mint an ID token for the Cloud Run URL.
       * This requires your function's runtime service account to have roles/run.invoker
       * (we’ll wire that in the next step).
       */
      const auth = new GoogleAuth();
      const client = await auth.getIdTokenClient(CONVERTER_URL);

      const resp = await client.request({
        url: CONVERTER_URL,
        method: "POST",
        data: { bucket, filePath }
      });

      const data = resp.data as any;

      if (!data || data.status !== "ok") {
        throw new Error(`Converter returned non-ok: ${JSON.stringify(data)}`);
      }

      const slides: string[] = Array.isArray(data.slides) ? data.slides : [];
      const pdfPages: number | null =
        typeof data.pdfPages === "number" ? data.pdfPages : null;

      logger.info("Conversion complete", {
        deckId,
        slideCount: slides.length,
        pdfPages
      });

      await db.collection(DECKS_COLLECTION).doc(deckId).update({
        [slidesField]: slides,
        [slideCountField]: slides.length,
        [pdfPagesField]: pdfPages,
        [convertedAtField]: new Date().toISOString(),
        [conversionStatusField]: "done",
        [conversionErrorField]: null
      });
    } catch (err: any) {
      logger.error("Conversion failed", {
        deckId,
        message: err?.message ?? String(err)
      });

      await db.collection(DECKS_COLLECTION).doc(deckId).update({
        [conversionStatusField]: "error",
        [conversionErrorField]: err?.message ?? String(err)
      });

      // Throw so retry (if enabled) can happen for transient errors
      throw err;
    }
  }
);
