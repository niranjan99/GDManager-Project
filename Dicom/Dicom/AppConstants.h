//
//  AppConstants.h
//  Dicom
//
//  Created by Sankar Dhekshit on 01/03/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#ifndef AppConstants_h
#define AppConstants_h

typedef enum DicomSearchType{
    DicomSearchTypeFirstName,
    DicomSearchTypeLastName,
    DicomSearchTypePatientID,
    DicomSearchTypeDob,
    DicomSearchTypeModality,
    DicomSearchTypeAETitle,
    DicomSearchTypeProcedureID,
    DicomSearchTypeAccessionNumber,
    DicomSearchTypeProcedureDate,
    DicomSearchTypeIsMWL
} DicomSearchType;

#endif /* AppConstants_h */
