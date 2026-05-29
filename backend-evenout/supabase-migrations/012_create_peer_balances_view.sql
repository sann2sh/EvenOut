-- ============================================================
-- 012: PEER_BALANCES VIEW
-- Dynamically calculates net debts between users
-- Net balances are NEVER stored statically — always computed
-- ============================================================

CREATE OR REPLACE VIEW public.peer_balances AS
WITH total_owed AS (
    SELECT 
        es.user_id AS debtor_id,
        e.paid_by AS creditor_id,
        e.group_id,
        SUM(es.amount_owed) AS amount
    FROM public.expense_splits es
    JOIN public.expenses e ON es.expense_id = e.id
    WHERE es.is_settled = FALSE
      AND e.is_deleted = FALSE
    GROUP BY es.user_id, e.paid_by, e.group_id
),
total_paid AS (
    SELECT 
        payer_id AS debtor_id,
        payee_id AS creditor_id,
        group_id,
        SUM(amount) AS amount
    FROM public.settlements
    WHERE status = 'confirmed'
    GROUP BY payer_id, payee_id, group_id
)
SELECT 
    COALESCE(o.debtor_id, p.debtor_id) AS user_id,
    COALESCE(o.creditor_id, p.creditor_id) AS counterpart_id,
    COALESCE(o.group_id, p.group_id) AS group_id,
    COALESCE(o.amount, 0) - COALESCE(p.amount, 0) AS net_debt
FROM total_owed o
FULL OUTER JOIN total_paid p 
ON o.debtor_id = p.debtor_id 
   AND o.creditor_id = p.creditor_id
   AND o.group_id IS NOT DISTINCT FROM p.group_id;

COMMENT ON VIEW public.peer_balances IS 'Dynamic net-debt calculation between users';
