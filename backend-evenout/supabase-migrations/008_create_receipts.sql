-- ============================================================
-- 008: RECEIPTS TABLE
-- Receipt images and OCR processing results (1:1 with expenses)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.receipts (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  expense_id        UUID NOT NULL REFERENCES public.expenses(id) ON DELETE CASCADE UNIQUE,
  storage_path      TEXT,
  public_url        TEXT,
  raw_ocr_text      JSONB,
  parsed_line_items JSONB,
  ocr_status        TEXT NOT NULL DEFAULT 'pending'
                    CHECK (ocr_status IN ('pending', 'processing', 'completed', 'failed')),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.receipts IS 'Receipt images and OCR-parsed line items (one per expense)';
