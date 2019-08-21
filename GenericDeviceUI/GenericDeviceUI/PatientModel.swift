
import Foundation
import Czm_GenericDevice_DataManagement_Interfaces
public class PatientModel {
    
    func addPatientData(patient:Patient, key:String) -> Patient{
        
        patient.patientKey = key
        patient.key = key
        patient.id = "1001"
        patient.issuerOfPatientId = "zeiss"
        patient.issuerOfPatientId = "zeiss_conflict1"
        patient.issuerOfPatientId = "zeiss_conflict2"
        patient.birthDate = "22/12/2019 22:21:58 PM"
        patient.sex = "M"
        patient.ethnicGroup = "sd"
        patient.isInArchive = true
        patient.comments = "sdsdfdsfsd fds f dsf dsf sd"
        patient.creationDate = "22/12/2019 22:21:58 PM"
        patient.otherPatientIds = ""
        patient.owner = UUID().uuidString
        patient.familyName = "dsfdsf"
        patient.givenName = "23esdsd"
        patient.middleName = "sdafsdf"
        patient.prefix = "prdsf"
        patient.suffix = "sdfd"
        patient.familyName_Ideographic = "familyName_Ideographic"
        patient.givenName_Ideographic = "givenName_Ideographic"
        patient.middleName_Ideographic = "middleName_Ideographic"
        patient.prefix_Ideographic = "prefix_Ideographic"
        patient.suffix_Ideographic = "suffix_Ideographic"
        patient.familyName_Phonetic = "suffix_Ideographic"
        patient.givenName_Phonetic = "givenName_Phonetic"
        patient.middleName_Phonetic = "middleName_Phonetic"
        patient.prefix_Phonetic = "prefix_Phonetic"
        patient.suffix_Phonetic = "suffix_Phonetic"
        return patient
        
    }
}

