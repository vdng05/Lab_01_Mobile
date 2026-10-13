import { initializeApp } from "firebase-admin/app";
import { getStorage } from "firebase-admin/storage";
import { createClient } from "@supabase/supabase-js";
import { defineSecret, defineString } from "firebase-functions/params";
import { HttpsError, onCall } from "firebase-functions/v2/https";

initializeApp();

const supabaseUrl = defineString("SUPABASE_URL");
const supabaseServiceRoleKey = defineSecret("SUPABASE_SERVICE_ROLE_KEY");

export const createDocumentDownloadUrl = onCall(
  { secrets: [supabaseServiceRoleKey], maxInstances: 20 },
  async (request) => {
    const userId = request.auth?.uid;
    const path = request.data?.path;
    if (!userId) throw new HttpsError("unauthenticated", "Sign-in required.");
    if (typeof path !== "string" || path.length > 1024) {
      throw new HttpsError("invalid-argument", "Invalid storage path.");
    }

    const supabase = createClient(
      supabaseUrl.value(),
      supabaseServiceRoleKey.value(),
      { auth: { persistSession: false, autoRefreshToken: false } },
    );
    const { data: document, error } = await supabase
      .from("documents")
      .select("id, owner_id, attachment_path")
      .eq("attachment_path", path)
      .maybeSingle();
    if (error) {
      throw new HttpsError("internal", "Unable to verify document access.");
    }
    if (!document) throw new HttpsError("not-found", "Document not found.");
    const expectedPrefix = `users/${document.owner_id}/documents/${document.id}/`;
    if (!path.startsWith(expectedPrefix)) {
      throw new HttpsError("permission-denied", "Invalid document storage path.");
    }

    let allowed = document.owner_id === userId;
    if (!allowed) {
      const { data: permission, error: permissionError } = await supabase
        .from("document_permissions")
        .select("access_level")
        .eq("document_id", document.id)
        .eq("user_id", userId)
        .maybeSingle();
      if (permissionError) {
        throw new HttpsError("internal", "Unable to verify document access.");
      }
      allowed = permission != null;
    }
    if (!allowed) {
      throw new HttpsError("permission-denied", "No access to this file.");
    }

    const expiresAt = Date.now() + 5 * 60 * 1000;
    const [url] = await getStorage()
      .bucket()
      .file(path)
      .getSignedUrl({ action: "read", expires: expiresAt });
    return { url, expiresAt };
  },
);