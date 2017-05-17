/*********************************************************************************************************
TITLE: formats_mha_events.sas

DESCRIPTION: Produce all the formats required to run
the creation of mha related events datasets

INPUT:
NA

OUTPUT:
$icd9sgl.



AUTHOR: V Benny

DATE: 06 April 2017

NOTES: 

HISTORY: 
06 April 2017 	V Benny	 	v1
*********************************************************************************************************/

proc format;
 value $icd9sgl
 	000 = ' '
	001='Neoplasms'
	002='Diseases of the respiratory system'
	003='Burns'
	004='Pregnancy and complications of puerperum'
	005='Pregnancy and complications of puerperum'
	006='Drug abuse'
	007='Drug abuse'
	008='Mental retardation'
	009='Other psychological/psychiatric conditions'
	010='Disorders of the central nervous system'
	011='Disorders of the central nervous system'
	012='Other neurosensory disorders'
	013='Disorders of the eye and adnexa'
	014='Disorders of the eye and adnexa'
	015='Disorders of the ear and mastoid process'
	016='Disorders of the ear and mastoid process'
	017='Other cardiovascular system diseases'
	018='Other cardiovascular system diseases'
	019='Fractures,dislocation,sprains and strains'
	020='Fractures,dislocation,sprains and strains'
	021='Poisoning,toxic effects'
	022='Other injuries'
	023='Infectious and parasitic diseases'
	024='Infectious and parasitic diseases'
	025='Arthropathies,rheumatism,osteopathies,chondropathies,acquired musculoskeletal deformities'
	026='Congenital abnormalities'
	027='Diseases of blood and blood forming organs'
	028='Metabolic and endocrine disorders'
	029='Diseases of the digestive system'
	030='Diseases of the genitourinary system'
	031='Symptoms,signs,ill defined conditions'
	032='Diseases of the skin and subcutaneous tissue'
	033='Intercranial and internal injuries, including nerves'
	034='Other injuries'
	035='Other injuries'
	036='Other injuries'
	070='Unspecified'
	101='Pregnancy and complications of puerperum'
	102='Pregnancy and complications of puerperum'
	103='Congenital abnormalities'
	104='Neoplasms'
	105='Infectious and parasitic diseases'
	106='Arthropathies,rheumatism,osteopathies,chondropathies,acquired musculoskeletal deformities'
	107='Diseases of the respiratory system'
	108='Diseases of the genitourinary system'
	109='Diseases of blood and blood forming organs'
	110='Diseases of the skin and subcutaneous tissue'
	111='Diseases of the digestive system'
	120='Disorders of the central nervous system'
	121='Disorders of the central nervous system'
	122='Disorders of the central nervous system'
	123='Disorders of the peripheral nervous system'
	124='Other neurosensory disorders'
	130='Other cardiovascular system diseases'
	131='Cerebrovascular disease'
	132='Other cardiovascular system diseases'
	140='Disorders involving the immune mechanism'
	141='Disorders involving the immune mechanism'
	150='Metabolic and endocrine disorders'
	151='Metabolic and endocrine disorders'
	160='Other psychological/psychiatric conditions'
	161='Affective psychoses'
	162='Affective psychoses'
	163='Other psychological/psychiatric conditions'
	164='Mental retardation'
	165='Other psychological/psychiatric conditions'
	170='Drug abuse'
	171='Drug abuse'
	172='Drug abuse'
	180='Disorders of the eye and adnexa'
	181='Disorders of the eye and adnexa'
	182='Disorders of the ear and mastoid process'
	183='Other neurosensory disorders'
	190='Burns'
	191='Fractures,dislocation,sprains and strains'
	192='Poisoning,toxic effects'
	193='Intercranial and internal injuries, including nerves'
	194='Intercranial and internal injuries, including nerves'
	195='Dorsopathies'
	196='Arthropathies,rheumatism,osteopathies,chondropathies,acquired musculoskeletal deformities'
	197='Other injuries'
	198='Other injuries'
	500='Symptoms,signs,ill defined conditions'
	501='Other injuries'
	502='Other injuries'
	503='Other cardiovascular system diseases'
	999='Designated doctors review, no medical entitlement';
run;