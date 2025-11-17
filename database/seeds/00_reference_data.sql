-- PAKAR Tech Healthcare Database - Reference Data
-- COS 20031 Database Design Project
-- File: 00_reference_data.sql
-- Purpose: Load core medical reference data (conditions, medications)

BEGIN;

SET search_path TO app, public;

-- ============================================================================
-- SECTION 1: MEDICAL CONDITIONS
-- ============================================================================

INSERT INTO app.condition (condition_name, condition_desc) VALUES
('Hypertension', 'Chronic high blood pressure (BP ≥ 140/90 mmHg)'),
('Type 2 Diabetes Mellitus', 'Non-insulin-dependent diabetes, impaired glucose metabolism'),
('Asthma', 'Chronic inflammatory respiratory condition with airway obstruction'),
('Migraine', 'Severe recurring headaches, often with visual disturbances'),
('Rheumatoid Arthritis', 'Autoimmune joint inflammation causing pain and swelling'),
('Gastroesophageal Reflux Disease', 'Chronic acid reflux from stomach to esophagus'),
('Hyperlipidemia', 'Elevated cholesterol and triglyceride levels'),
('Chronic Kidney Disease', 'Progressive loss of kidney function over time'),
('Major Depressive Disorder', 'Persistent feelings of sadness and loss of interest'),
('Generalized Anxiety Disorder', 'Excessive, uncontrollable worry about daily events'),
('Headache', 'Pain in the head or upper neck region'),
('Nausea', 'Feeling of sickness with urge to vomit'),
('Dizziness', 'Sensation of lightheadedness or loss of balance'),
('Fatigue', 'Extreme tiredness or lack of energy'),
('Fever', 'Elevated body temperature above 38°C (100.4°F)'),
('Cough', 'Sudden expulsion of air from lungs, may be dry or productive'),
('Chest Pain', 'Discomfort or pain in chest area, may radiate'),
('Shortness of Breath', 'Difficulty breathing or feeling breathless'),
('Abdominal Pain', 'Pain in stomach or abdomen area'),
('Joint Pain', 'Pain, stiffness, or swelling in one or more joints'),
('Drowsiness', 'Feeling abnormally sleepy during the day'),
('Dry Mouth', 'Reduced saliva production, mouth feels dry'),
('Diarrhea', 'Loose or watery bowel movements'),
('Constipation', 'Difficulty passing stools, infrequent bowel movements'),
('Insomnia', 'Difficulty falling asleep or staying asleep'),
('Weight Gain', 'Unintended increase in body weight'),
('Skin Rash', 'Red, itchy, or inflamed skin condition')
ON CONFLICT (condition_name) DO NOTHING;

-- ============================================================================
-- SECTION 2: SYMPTOMS (Patient-Reported)
-- ============================================================================

INSERT INTO app.symptom (condition_id)
SELECT condition_id FROM app.condition 
WHERE condition_name IN (
    'Headache',
    'Nausea',
    'Dizziness',
    'Fatigue',
    'Fever',
    'Cough',
    'Chest Pain',
    'Shortness of Breath',
    'Abdominal Pain',
    'Joint Pain'
)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SECTION 3: SIDE EFFECTS (Medication-Caused)
-- ============================================================================

INSERT INTO app.side_effect (condition_id)
SELECT condition_id FROM app.condition 
WHERE condition_name IN (
    'Headache',
    'Nausea',
    'Dizziness',
    'Fatigue',
    'Drowsiness',
    'Dry Mouth',
    'Diarrhea',
    'Constipation',
    'Insomnia',
    'Weight Gain',
    'Skin Rash'
)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SECTION 4: MEDICATIONS
-- ============================================================================

INSERT INTO app.medication (med_name, med_brand_name, med_manufacturer, med_desc) VALUES
('Metformin Hydrochloride', 'Glucophage', 'Bristol-Myers Squibb', 'First-line oral antidiabetic medication for Type 2 Diabetes'),
('Amlodipine Besylate', 'Norvasc', 'Pfizer', 'Calcium channel blocker for hypertension and angina'),
('Lisinopril', 'Prinivil', 'Merck', 'ACE inhibitor for hypertension and heart failure'),
('Atorvastatin Calcium', 'Lipitor', 'Pfizer', 'HMG-CoA reductase inhibitor (statin) for lowering cholesterol'),
('Omeprazole', 'Prilosec', 'AstraZeneca', 'Proton pump inhibitor for acid reflux and GERD'),
('Salbutamol Sulfate', 'Ventolin', 'GlaxoSmithKline', 'Short-acting beta-agonist bronchodilator for asthma'),
('Paracetamol', 'Panadol', 'GlaxoSmithKline', 'Analgesic and antipyretic for pain and fever'),
('Ibuprofen', 'Advil', 'Pfizer', 'NSAID for pain, inflammation, and fever'),
('Amoxicillin', 'Amoxil', 'GlaxoSmithKline', 'Beta-lactam antibiotic for bacterial infections'),
('Cetirizine Hydrochloride', 'Zyrtec', 'Johnson & Johnson', 'Second-generation antihistamine for allergies'),
('Losartan Potassium', 'Cozaar', 'Merck', 'Angiotensin II receptor blocker for hypertension'),
('Simvastatin', 'Zocor', 'Merck', 'Statin for lowering LDL cholesterol'),
('Aspirin', 'Bayer', 'Bayer', 'Antiplatelet and anti-inflammatory medication'),
('Furosemide', 'Lasix', 'Sanofi', 'Loop diuretic for fluid retention and hypertension'),
('Levothyroxine Sodium', 'Synthroid', 'AbbVie', 'Thyroid hormone replacement therapy')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SECTION 5: MEDICATION-SIDE EFFECT LINKS
-- ============================================================================

-- Link medications to common side effects
DO $$
DECLARE
    metformin_id INT;
    amlodipine_id INT;
    omeprazole_id INT;
    
    nausea_se_id INT;
    dizziness_se_id INT;
    headache_se_id INT;
    diarrhea_se_id INT;
BEGIN
    -- Get medication IDs
    SELECT medication_id INTO metformin_id FROM app.medication WHERE med_name = 'Metformin Hydrochloride';
    SELECT medication_id INTO amlodipine_id FROM app.medication WHERE med_name = 'Amlodipine Besylate';
    SELECT medication_id INTO omeprazole_id FROM app.medication WHERE med_name = 'Omeprazole';
    
    -- Get side effect IDs (through condition)
    SELECT se.side_effect_id INTO nausea_se_id 
    FROM app.side_effect se 
    JOIN app.condition c ON se.condition_id = c.condition_id 
    WHERE c.condition_name = 'Nausea' LIMIT 1;
    
    SELECT se.side_effect_id INTO dizziness_se_id 
    FROM app.side_effect se 
    JOIN app.condition c ON se.condition_id = c.condition_id 
    WHERE c.condition_name = 'Dizziness' LIMIT 1;
    
    SELECT se.side_effect_id INTO headache_se_id 
    FROM app.side_effect se 
    JOIN app.condition c ON se.condition_id = c.condition_id 
    WHERE c.condition_name = 'Headache' LIMIT 1;
    
    SELECT se.side_effect_id INTO diarrhea_se_id 
    FROM app.side_effect se 
    JOIN app.condition c ON se.condition_id = c.condition_id 
    WHERE c.condition_name = 'Diarrhea' LIMIT 1;
    
    -- Link medications to side effects
    INSERT INTO app.medication_side_effect (medication_id, side_effect_id, frequency) VALUES
    (metformin_id, nausea_se_id, 'Common'),
    (metformin_id, diarrhea_se_id, 'Common'),
    (amlodipine_id, dizziness_se_id, 'Common'),
    (amlodipine_id, headache_se_id, 'Common'),
    (omeprazole_id, headache_se_id, 'Common'),
    (omeprazole_id, nausea_se_id, 'Uncommon')
    ON CONFLICT (medication_id, side_effect_id) DO NOTHING;
END $$;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    condition_count INT;
    symptom_count INT;
    side_effect_count INT;
    medication_count INT;
    med_se_count INT;
BEGIN
    SELECT COUNT(*) INTO condition_count FROM app.condition;
    SELECT COUNT(*) INTO symptom_count FROM app.symptom;
    SELECT COUNT(*) INTO side_effect_count FROM app.side_effect;
    SELECT COUNT(*) INTO medication_count FROM app.medication;
    SELECT COUNT(*) INTO med_se_count FROM app.medication_side_effect;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Reference Data Loaded Successfully';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Conditions: % records', condition_count;
    RAISE NOTICE 'Symptoms: % records', symptom_count;
    RAISE NOTICE 'Side Effects: % records', side_effect_count;
    RAISE NOTICE 'Medications: % records', medication_count;
    RAISE NOTICE 'Med-SideEffect Links: % records', med_se_count;
    RAISE NOTICE '========================================';
END $$;

COMMIT;