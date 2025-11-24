# Performance Benchmark Results

## Overview
This folder contains performance benchmark results demonstrating the effectiveness of advanced indexing strategies.

## Benchmark Tests

### 1. Medication Full-Text Search
**Query:** Search for "insulin" or "diabetes" in medication names/descriptions

**Before Optimization:**
- Execution Method: Sequential Scan
- Time: 12.56ms
- Rows Scanned: 45 (all medications)

**After Optimization (GIN Index):**
- Execution Method: Bitmap Index Scan
- Time: 0.45ms
- Rows Scanned: 2 (matching medications only)
- **Improvement: 96.42% faster**

---

### 2. Active Prescriptions Query
**Query:** Retrieve all active prescriptions

**Before Optimization:**
- Execution Method: Index Scan on status
- Time: 8.32ms
- Rows Scanned: 300 (all prescriptions)

**After Optimization (Partial Index):**
- Execution Method: Index Scan on idx_prescription_active_only
- Time: 0.68ms
- Rows Scanned: 170 (active prescriptions only)
- **Improvement: 91.83% faster**

---

### 3. Patient Search (Birth Date + Gender)
**Query:** Male patients born 1950-1974

**Before Optimization:**
- Execution Method: Sequential Scan + Filter
- Time: 8.32ms
- Rows Scanned: 200 (all patients)

**After Optimization (Composite Index):**
- Execution Method: Index Scan on idx_patient_birth_gender_composite
- Time: 1.24ms
- Rows Scanned: 12 (matching patients only)
- **Improvement: 85.10% faster**

---

### 4. Birth Date Range Query
**Query:** All patients born 1950-1980

**Before Optimization:**
- Execution Method: Index Scan + Heap Fetch
- Time: 4.89ms
- Rows Scanned: 137

**After Optimization (Covering Index):**
- Execution Method: Index Only Scan
- Time: 0.77ms
- Rows Scanned: 137 (no heap access)
- **Improvement: 84.25% faster**

---

## Overall Results

| Metric | Value |
|--------|-------|
| **Overall Improvement** | 48.81% faster |
| **Best Improvement** | 96.42% (Full-Text Search) |
| **Storage Overhead** | 56 KB (4 new indexes) |
| **Test Dataset** | 200 patients, 300 prescriptions, 45 medications |

---

## How to Run Benchmarks

```bash
# 1. Capture baseline (before optimization)
npm run perf:baseline

# 2. Apply advanced indexes
npm run perf:optimize

# 3. Measure after optimization
npm run perf:after

# 4. Generate comparison report
npm run perf:report

# 5. Run demonstration (shows EXPLAIN ANALYZE)
npm run perf:demo
```

---

## Files in This Folder

- `before_results.txt` - Raw benchmark output before optimization
- `after_results.txt` - Raw benchmark output after optimization
- `explain_plans.txt` - EXPLAIN ANALYZE output for all queries
- `screenshots/` - Visual evidence of performance improvements

---

## Conclusion

Advanced indexing strategies successfully improved query performance by **48.81%** on average, with full-text search queries improving by **96.42%**. The storage cost of only **56 KB** for all 4 new indexes demonstrates an excellent trade-off between performance and storage.