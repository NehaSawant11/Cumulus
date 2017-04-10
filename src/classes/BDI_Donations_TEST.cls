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
    'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
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
* @description tests specific to the Batch Data Importer Donations batch processing and record creation
*/

@isTest
public with sharing class BDI_Donations_TEST {

    /*********************************************************************************************************
    * @description if you only want to run one test in this class, fill in its name here.
    * if you want to run all tests, then use '*'
    */
    private static string strTestOnly = '*';

    /*********************************************************************************************************
    * @description holds test Contacts for BDI donations tests
    */
    private static List<Contact> listConT;
    
    /*********************************************************************************************************
    * @description holds test Opps for use in BDI donations tests
    */
    private static list<Opportunity> listOppT;
    
    /*********************************************************************************************************
    * @description create test contacts and donations for use in BDI donations tests
    */
    static void createTestData() {
        listConT = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(2);
        insert listConT;

        listOppT = UTIL_UnitTestData_TEST.OppsForContactList(listConT, null, 
            UTIL_unitTestData_TEST.getOpenStage(), system.Today(), 100, null, null);
        insert listOppT;
    }

    /*********************************************************************************************************
    * @description operation
    *        import existing contacts with existiong open Opportunities  
    * verify: 
    *       opportunity objects matched & closed
    *       payment objects updated
    */
    static testMethod void TwoDIWithExistingDonations() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDIWithExistingDonations') return;
        
        createTestData();
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c=listConT[0].Firstname, Contact1_Lastname__c=listConT[0].Lastname, 
            Contact1_Work_Email__c=listConT[0].npe01__WorkEmail__c));
        listDI.add(new DataImport__c(Contact1_Firstname__c=listConT[1].Firstname, Contact1_Lastname__c=listConT[1].Lastname, 
            Contact1_Work_Email__c=listConT[1].npe01__WorkEmail__c));
        listDI[0].Donation_Amount__c = listOppT[0].Amount;
        listDI[0].Donation_Date__c = listOppT[0].CloseDate;
        listDI[1].Donation_Amount__c = listOppT[1].Amount;
        listDI[1].Donation_Date__c = listOppT[1].CloseDate;
        listDI[0].Payment_Check_Reference_Number__c = 'abc';
        listDI[1].Payment_Check_Reference_Number__c = '1234';
        listDI[0].Payment_Method__c = 'Check';
        listDI[1].Payment_Method__c = 'Visa';       
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name, AccountId, npo02__TotalOppAmount__c from Contact order by Firstname];
        system.assertEquals(2, listCon.size());
        system.assertEquals(listOppT[0].Amount, listCon[0].npo02__TotalOppAmount__c);
        system.assertEquals(listOppT[1].Amount, listCon[1].npo02__TotalOppAmount__c);
        
        list<Account> listAcc = [select Id, Name, npo02__TotalOppAmount__c from Account order by Name];
        system.assertEquals(2, listAcc.size());
        system.assertEquals(listOppT[0].Amount, listAcc[0].npo02__TotalOppAmount__c);
        system.assertEquals(listOppT[1].Amount, listAcc[1].npo02__TotalOppAmount__c);
        
        list<Opportunity> listOpp = [select Id, Name, Amount, StageName, isWon, isClosed, AccountId from Opportunity order by Name];
        system.assertEquals(2, listOpp.size());
        system.assertEquals(true, listOpp[0].isWon);
        system.assertEquals(true, listOpp[1].isWon);
        
        list<npe01__OppPayment__c> listPmt = [select Id, npe01__Payment_Amount__c, npe01__Payment_Method__c, npe01__Check_Reference_Number__c from npe01__OppPayment__c order by npe01__Opportunity__r.Name];
        system.assertEquals(2, listPmt.size());
        system.assertEquals('Check', listPmt[0].npe01__Payment_Method__c);
        system.assertEquals('Visa', listPmt[1].npe01__Payment_Method__c);
        system.assertEquals('abc', listPmt[0].npe01__Check_Reference_Number__c);
        system.assertEquals('1234', listPmt[1].npe01__Check_Reference_Number__c);

        listDI = [select Id, DonationImported__c, DonationImportStatus__c from DataImport__c order by Contact1_Lastname__c];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].DonationImported__c, listOpp[0].Id); 
        system.assertEquals(listDI[1].DonationImported__c, listOpp[1].Id);
        system.assertEquals(label.bdiMatched, listDI[0].DonationImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[1].DonationImportStatus__c);        
    }
    
    /*********************************************************************************************************
    * @description operation
    *        import existing contacts with existiong open Opportunities specified in DonationImported__c  
    * verify: 
    *       opportunity objects matched & closed
    *       payment objects updated
    */
    static testMethod void TwoDIWithExistingDonationsSpecified() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDIWithExistingDonationsSpecified') return;
        
        createTestData();
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c=listConT[0].Firstname, Contact1_Lastname__c=listConT[0].Lastname, 
            Contact1_Work_Email__c=listConT[0].npe01__WorkEmail__c));
        listDI.add(new DataImport__c(Contact1_Firstname__c=listConT[1].Firstname, Contact1_Lastname__c=listConT[1].Lastname, 
            Contact1_Work_Email__c=listConT[1].npe01__WorkEmail__c));

        listDI[0].Donation_Amount__c = listOppT[0].Amount;
        listDI[0].Donation_Date__c = listOppT[0].CloseDate;
        listDI[0].DonationImported__c = listOppT[0].Id;
        listDI[0].Payment_Check_Reference_Number__c = 'abc';
        listDI[0].Payment_Method__c = 'Check';

        listDI[1].Donation_Amount__c = listOppT[1].Amount;
        listDI[1].Donation_Date__c = listOppT[1].CloseDate;
        listDI[1].DonationImported__c = listOppT[1].Id;
        listDI[1].Payment_Check_Reference_Number__c = '1234';
        listDI[1].Payment_Method__c = 'Visa';       
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name, AccountId, npo02__TotalOppAmount__c from Contact order by Firstname];
        system.assertEquals(2, listCon.size());
        system.assertEquals(listOppT[0].Amount, listCon[0].npo02__TotalOppAmount__c);
        system.assertEquals(listOppT[1].Amount, listCon[1].npo02__TotalOppAmount__c);
        
        list<Account> listAcc = [select Id, Name, npo02__TotalOppAmount__c from Account order by Name];
        system.assertEquals(2, listAcc.size());
        system.assertEquals(listOppT[0].Amount, listAcc[0].npo02__TotalOppAmount__c);
        system.assertEquals(listOppT[1].Amount, listAcc[1].npo02__TotalOppAmount__c);
        
        list<Opportunity> listOpp = [select Id, Name, Amount, StageName, isWon, isClosed, AccountId from Opportunity order by Name];
        system.assertEquals(2, listOpp.size());
        system.assertEquals(true, listOpp[0].isWon);
        system.assertEquals(true, listOpp[1].isWon);
        
        list<npe01__OppPayment__c> listPmt = [select Id, npe01__Payment_Amount__c, npe01__Payment_Method__c, npe01__Check_Reference_Number__c from npe01__OppPayment__c order by npe01__Opportunity__r.Name];
        system.assertEquals(2, listPmt.size());
        system.assertEquals('Check', listPmt[0].npe01__Payment_Method__c);
        system.assertEquals('Visa', listPmt[1].npe01__Payment_Method__c);
        system.assertEquals('abc', listPmt[0].npe01__Check_Reference_Number__c);
        system.assertEquals('1234', listPmt[1].npe01__Check_Reference_Number__c);

        listDI = [select Id, DonationImported__c, DonationImportStatus__c from DataImport__c order by Contact1_Lastname__c];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].DonationImported__c, listOpp[0].Id); 
        system.assertEquals(listDI[1].DonationImported__c, listOpp[1].Id);
        system.assertEquals(label.bdiMatched, listDI[0].DonationImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[1].DonationImportStatus__c);        
    }
    
    /*********************************************************************************************************
    * @description operation
    *        import existing contacts with existing open Opportunities, and duplicate Donations  
    * verify: 
    *       opportunity objects matched & closed
    *       duplicate Donation doesn't match to same Opp, but creates a new Opp
    *       payment objects updated
    */
    static testMethod void TwoDIWithExistingDonationsOneDupe() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDIWithExistingDonationsOneDupe') return;
        
        createTestData();
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c=listConT[0].Firstname, Contact1_Lastname__c=listConT[0].Lastname, 
            Contact1_Work_Email__c=listConT[0].npe01__WorkEmail__c));
        listDI.add(new DataImport__c(Contact1_Firstname__c=listConT[1].Firstname, Contact1_Lastname__c=listConT[1].Lastname, 
            Contact1_Work_Email__c=listConT[1].npe01__WorkEmail__c));
        listDI.add(new DataImport__c(Contact1_Firstname__c=listConT[1].Firstname, Contact1_Lastname__c=listConT[1].Lastname, 
            Contact1_Work_Email__c=listConT[1].npe01__WorkEmail__c));

        listDI[0].Donation_Amount__c = listOppT[0].Amount;
        listDI[0].Donation_Date__c = listOppT[0].CloseDate;
        listDI[0].Payment_Check_Reference_Number__c = 'abc';
        listDI[0].Payment_Method__c = 'Check';

        listDI[1].Donation_Amount__c = listOppT[1].Amount;
        listDI[1].Donation_Date__c = listOppT[1].CloseDate;
        listDI[1].Payment_Check_Reference_Number__c = '1234';
        listDI[1].Payment_Method__c = 'Visa';       

        listDI[2].Donation_Amount__c = listOppT[1].Amount;
        listDI[2].Donation_Date__c = listOppT[1].CloseDate;
        listDI[2].Payment_Check_Reference_Number__c = '5678';
        listDI[2].Payment_Method__c = 'Mastercard';       
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name, AccountId, npo02__TotalOppAmount__c from Contact order by Firstname];
        system.assertEquals(2, listCon.size());
        system.assertEquals(listOppT[0].Amount, listCon[0].npo02__TotalOppAmount__c);
        system.assertEquals(listOppT[1].Amount * 2, listCon[1].npo02__TotalOppAmount__c);
        
        list<Account> listAcc = [select Id, Name, npo02__TotalOppAmount__c from Account order by npe01__One2OneContact__r.Firstname];
        system.assertEquals(2, listAcc.size());
        system.assertEquals(listOppT[0].Amount, listAcc[0].npo02__TotalOppAmount__c);
        system.assertEquals(listOppT[1].Amount * 2, listAcc[1].npo02__TotalOppAmount__c);
        
        list<Opportunity> listOpp = [select Id, Name, Amount, StageName, isWon, isClosed, AccountId from Opportunity order by Name];
        system.assertEquals(3, listOpp.size());
        system.assertEquals(true, listOpp[0].isWon);
        system.assertEquals(true, listOpp[1].isWon);
        system.assertEquals(true, listOpp[2].isWon);
        
        list<npe01__OppPayment__c> listPmt = [select Id, npe01__Payment_Amount__c, npe01__Payment_Method__c, npe01__Check_Reference_Number__c from npe01__OppPayment__c order by npe01__Opportunity__r.Name];
        system.assertEquals(3, listPmt.size());
        system.assertEquals('Check', listPmt[0].npe01__Payment_Method__c);
        system.assertEquals('abc', listPmt[0].npe01__Check_Reference_Number__c);
        system.assertEquals('Visa', listPmt[1].npe01__Payment_Method__c);
        system.assertEquals('1234', listPmt[1].npe01__Check_Reference_Number__c);
        system.assertEquals('Mastercard', listPmt[2].npe01__Payment_Method__c);
        system.assertEquals('5678', listPmt[2].npe01__Check_Reference_Number__c);

        listDI = [select Id, DonationImported__c, DonationImportStatus__c from DataImport__c order by Contact1_Lastname__c];
        system.assertEquals(3, listDI.size());
        system.assertEquals(listDI[0].DonationImported__c, listOpp[0].Id); 
        system.assertEquals(listDI[1].DonationImported__c, listOpp[1].Id);
        system.assertEquals(listDI[2].DonationImported__c, listOpp[2].Id);
        system.assertEquals(label.bdiMatched, listDI[0].DonationImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[1].DonationImportStatus__c);        
        system.assertEquals(label.bdiCreated, listDI[2].DonationImportStatus__c);        
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  avoid same amount, different day.
    * verify: 
    *    correct donations matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules1() {
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules1') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=100,
            Donation_Date__c=System.Today(),
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            0, BDI_DataImport_API.ExactMatchOrCreate, label.bdiMatched, false);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  avoid different amount, same day.  
    * verify: 
    *    correct donations matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules2() {
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules2') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=300,
            Donation_Date__c=System.Today(),
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            4, BDI_DataImport_API.ExactMatchOrCreate, label.bdiMatched, false);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date, RecordType 
    * verify: 
    *    correct donations matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules3() {
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules3') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=200,
            Donation_Date__c=System.Today(),
            Donation_Record_Type_Name__c=UTIL_RecordTypes.getRecordTypeNameForMembershipTests(Opportunity.sObjectType),
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Record_Type_Name__c'),
            3, BDI_DataImport_API.ExactMatchOrCreate, label.bdiMatched, false);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Ambiguous match detected.
    * verify: 
    *    no donations matched
    *    ambiguous match error logged
    **********************************************************************************************************/            
    static testMethod void donationMatchRules4() {
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules4') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=200,
            Donation_Date__c=System.Today(),
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.ExactMatchOrCreate, label.bdiErrorDonationMultiMatch, true);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Ambiguous match detected.
    * verify: 
    *    best donation matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules5() {
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules5') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=200,
            Donation_Date__c=System.Today(),
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -2, BDI_DataImport_API.BestMatchOrCreate, label.bdiMatchedBest, true);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    the shared routine to actually test the different donations different matching rules. 
    * verify: 
    *    correct donations matched
    *
    * @param strRule The matching rules to use in the test
    * @param imatch The existing Opp we expect to match against.  use -1 if no match expected.  use -2 if best match expected (which can be random)
    * @param expectedStatus The status value we expect to be set in DonationImportStatus__c
    * @param hasMultiMatches Whether we expect anything in Donation_Possible_Matches__c
    **********************************************************************************************************/            
    static void donationMatchRules(string strRule, integer imatch, string matchBehavior, 
        string expectedStatus, boolean hasMultiMatches) { 
        
        // create opps to match against
        Contact con = new Contact(firstname='c0', lastname='c0', email='c0@c0.com');
        insert con;
        list<Opportunity> listOpp = new list<Opportunity>();
        listOpp.add(new Opportunity(name='Opp0', Primary_Contact__c=con.Id, Amount=100, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getOpenStage()));
        listOpp.add(new Opportunity(name='Opp1', Primary_Contact__c=con.Id, Amount=100, CloseDate=System.Today().addDays(-1), 
            StageName=UTIL_unitTestData_TEST.getOpenStage()));
        listOpp.add(new Opportunity(name='Opp2', Primary_Contact__c=con.Id, Amount=200, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getOpenStage()));
        listOpp.add(new Opportunity(name='Opp3', Primary_Contact__c=con.Id, Amount=200, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getOpenStage(), 
            RecordTypeId=UTIL_RecordTypes.getRecordTypeIdForMembershipTests(Opportunity.sObjectType)));
        listOpp.add(new Opportunity(name='Opp4', Primary_Contact__c=con.Id, Amount=300, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getOpenStage()));
        insert listOpp;

        // set the specified settings
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Donation_Matching_Rule__c = strRule;
        diSettings.Donation_Matching_Behavior__c = matchBehavior;
 
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify we matched an existing opp (no new opp created)
        list<Opportunity> listOppX = [select Id, Name, Amount, Primary_Contact__c from Opportunity];
        system.assertEquals(listOpp.size(), listOppX.size());
        
        list<DataImport__c> listDI = [select Status__c, DonationImported__c, DonationImportStatus__c, 
            Donation_Possible_Matches__c from DataImport__c];        
        system.assertEquals(1, listDI.size());
        system.assertEquals(expectedStatus, listDI[0].DonationImportStatus__c);                
        system.assertEquals(imatch == -1 ? label.bdiFailed : label.bdiImported, listDI[0].Status__c);
        system.assertEquals(hasMultiMatches, listDI[0].Donation_Possible_Matches__c != null);
        if (imatch == -1)
            system.assertEquals(null, listDI[0].DonationImported__c);
        else if (imatch != -2)
            system.assertEquals(listOpp[imatch].Id, listDI[0].DonationImported__c);
    }
}