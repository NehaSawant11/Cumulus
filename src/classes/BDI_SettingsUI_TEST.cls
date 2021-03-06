/*
    Copyright (c) 2017 Salesforce.org
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2017
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description tests specific to the Batch Data Importer Settings user interface
*/

@isTest
private with sharing class BDI_SettingsUI_TEST {

    /*********************************************************************************************************
    * @description operation: 
    *    ensure methods of controller are tested 
    * verify: 
    *    all code tested in controller
    **********************************************************************************************************/            
    static testMethod void testBDISettingsUI() {
        
        // instantiate the controller
        BDI_SettingsUI_CTRL ctrl = new BDI_SettingsUI_CTRL();
        ctrl.diSettings = new Data_Import_Settings__c();
        
        Test.startTest();
        system.assertEquals(false, ctrl.isEditMode);
        system.assertEquals(true, ctrl.isReadOnlyMode);
        system.assertNotEquals(null, ctrl.listSODonationFields);
        system.assertNotEquals(null, ctrl.listSOContactUniqueID);
        system.assertNotEquals(null, ctrl.listSOAccountUniqueID);
        Test.stopTest();
    }

    /*********************************************************************************************************
    * @description operation:
    *    test validation of save method
    * verify:
    *    errors detected
    **********************************************************************************************************/
    static testMethod void testBDISettingsUISaveValidation() {

        Data_Import_Settings__c diSettings = new Data_Import_Settings__c();

        Test.startTest();

        diSettings.Donation_Matching_Behavior__c = 'bogus value';
        system.assertEquals(false, BDI_SettingsUI_CTRL.saveBDISettings(diSettings));
        diSettings.Donation_Matching_Behavior__c = BDI_DataImport_API.BestMatchOrCreate;
        system.assertEquals(false, BDI_SettingsUI_CTRL.saveBDISettings(diSettings));
        diSettings.Donation_Matching_Rule__c = 'Donation_Date__c';
        system.assertEquals(true, BDI_SettingsUI_CTRL.saveBDISettings(diSettings));

        diSettings.Donation_Date_Range__c = -1;
        system.assertEquals(false, BDI_SettingsUI_CTRL.saveBDISettings(diSettings));
        diSettings.Donation_Date_Range__c = 1;
        system.assertEquals(true, BDI_SettingsUI_CTRL.saveBDISettings(diSettings));

        diSettings.Donation_Matching_Implementing_Class__c = 'foo';
        system.assertEquals(false, BDI_SettingsUI_CTRL.saveBDISettings(diSettings));
        diSettings.Donation_Matching_Implementing_Class__c = 'BDI_MatchDonations';
        system.assertEquals(true, BDI_SettingsUI_CTRL.saveBDISettings(diSettings));

        diSettings.Contact_Custom_Unique_ID__c = 'bogus field';
        system.assertEquals(false, BDI_SettingsUI_CTRL.saveBDISettings(diSettings));
        diSettings.Account_Custom_Unique_ID__c = 'bogus field';
        system.assertEquals(false, BDI_SettingsUI_CTRL.saveBDISettings(diSettings));

        Test.stopTest();
    }

}