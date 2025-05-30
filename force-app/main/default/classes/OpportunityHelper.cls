public with sharing class OpportunityHelper {

    public static void setDefaultType(List<Opportunity> opps) {

        //CRUD Validation 
        if (!Schema.sObjectType.Opportunity.isUpdateable()) {
            throw new System.SecurityException('You do not have permission to update Opportunity records.');
        }

        if (!Schema.sObjectType.Opportunity.fields.Type.isUpdateable()) {
            throw new System.SecurityException('You do not have access to update the Type field on Opportunity.');
        }

        //loop through opps to set type
        for (Opportunity opp : opps){
            if (opp.Type == null){
                opp.Type = 'New Customer'; 
            }
        }
    }

    public static void dontDeleteClosedOpps(List<Opportunity> opps){

        //CRUD Validation
        if (!Schema.sObjectType.Opportunity.isAccessible()) {
            throw new System.SecurityException('You do not have permission to update Opportunity records.');
        }
        
        //loop through opps to sent error message
        for (Opportunity oldOpp : opps){
            if (oldOpp.IsClosed){
                oldOpp.addError('Cannot delete closed opportunity');
            }
        }
    }

    public static void createTasks(List<Opportunity> opps){

        //CRUD Validation
        if (!Schema.sObjectType.Opportunity.isUpdateable()) {
            throw new System.SecurityException('You do not have permission to update Opportunity records.');
        }

        if (!Schema.sObjectType.Task.isCreateable()) {
            throw new System.SecurityException('You do not have permission to create Task records.');
        }

        if (!Schema.sObjectType.Task.fields.Subject.isUpdateable() ||
            !Schema.sObjectType.Task.fields.WhatId.isUpdateable() ||
            !Schema.sObjectType.Task.fields.WhoId.isUpdateable() ||
            !Schema.sObjectType.Task.fields.OwnerId.isUpdateable() ||
            !Schema.sObjectType.Task.fields.ActivityDate.isUpdateable()) {
            throw new System.SecurityException('You do not have access to update one or more fields on Task.');
        }

        //List of tasks to be created
        List<Task> tasksToCreate = new List<Task>();

            //loop through ups to set field values of the related task
            for (Opportunity opp : opps){
                Task tsk = new Task();
                tsk.Subject = 'Call Primary Contact';
                tsk.WhatId = opp.Id;
                tsk.WhoId = opp.Primary_Contact__c;
                tsk.OwnerId = opp.OwnerId;
                tsk.ActivityDate = Date.today().addDays(3);
                tasksToCreate.add(tsk);
            }
            insert tasksToCreate;
    }

    public static void updateDescriptionStage (List<Opportunity> opps){

        //CRUD Validation
        if (!Schema.sObjectType.Opportunity.isUpdateable()) {
            throw new System.SecurityException('You do not have permission to update Opportunity records.');
        }

        if (!Schema.sObjectType.Opportunity.fields.Description.isUpdateable()){
            throw new System.SecurityException('You do not have permission to update the Description field Opportunity records.');
        }

        //List of Opps to be updated
        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        //loop through opps to update description
        for (Opportunity opp : opps){
                if (opp.StageName != null) {
                    opp.Description += '\n Stage Change:' + Opp.StageName + ':' + Datetime.now().format();
                    oppsToUpdate.add(opp);
                }
            }
        update oppsToUpdate;
    }


    public static void notifyOwnersOpportunityDeleted(List<Opportunity> opps) {

        //CRUD Validation
        if (!Schema.sObjectType.Opportunity.isAccessible()) {
            throw new System.SecurityException('You do not have permission to read Opportunity records.');
        }
        if (!Schema.sObjectType.Opportunity.fields.OwnerId.isAccessible()) {
            throw new System.SecurityException('You do not have access to the OwnerId field on Opportunity.');
        }
        if (!Schema.sObjectType.User.isAccessible()) {
            throw new System.SecurityException('You do not have permission to read User records.');
        }
        if (!Schema.sObjectType.User.fields.Email.isAccessible()) {
            throw new System.SecurityException('You do not have access to the Email field on User.');
        }


        //List of mails to be sent
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        //created a set of owner Ids from the opps collection (the dot notation at the end of the soql was a cool trick)
        Set<Id> ownerIds = new Set<Id> {[SELECT OwnerId FROM Opportunity WHERE Id = :opps].OwnerId};

        //created a string of emails using the set of Ids
        String[] toAddresses = new String[] {[SELECT Id, Email FROM User WHERE Id = :ownerIds].Email};

        //Loop through opps to set email message fields
        for (Opportunity opp : opps){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAddresses);
            mail.setSubject('Opportunity Deleted : ' + opp.Name);
            mail.setPlainTextBody('Your Opportunity: ' + opp.Name +' has been deleted.');
            mails.add(mail);
        }        
        
        try {
            Messaging.sendEmail(mails);
        } catch (Exception e){
            System.debug('Exception: ' + e.getMessage());
        }
    }


    public static void assignPrimaryContact(Map<Id,Opportunity> oppNewMap) {        

        //CRUD Validation
        if (!Schema.sObjectType.Opportunity.isAccessible()) {
            throw new System.SecurityException('You do not have permission to read Opportunity records.');
        }

        if (!Schema.sObjectType.Opportunity.fields.AccountId.isAccessible()) {
            throw new System.SecurityException('You do not have access to the AccountId field on Opportunity.');
        }

        if (!Schema.sObjectType.Opportunity.fields.Primary_Contact__c.isUpdateable()) {
            throw new System.SecurityException('You do not have access to the AccountId field on Opportunity.');
        }
        
        if (!Schema.sObjectType.Account.isAccessible()) {
            throw new System.SecurityException('You do not have permission to read Account records.');
        }

        if (!Schema.sObjectType.Account.fields.Primary_Contact__c.isAccessible()) {
            throw new System.SecurityException('You do not have access to the AccountId field on Account.');
        }

        if (!Schema.sObjectType.Contact.isAccessible()) {
            throw new System.SecurityException('You do not have permission to read Contact records.');
        }

        if (!Schema.sObjectType.Contact.fields.Id.isAccessible()) {
            throw new System.SecurityException('You do not have access to the Id field on Contact.');
        }



        //Map of Opp Id and record to be used in setting the contact Id
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();

        //Set of Account Ids to be used in getting the Id of the primary contact
        Set<Id> accIds = new Set<Id> {[SELECT AccountId FROM Opportunity WHERE Id = :oppNewMap.keySet()].AccountId};

        //List of contacts with title VP of sales with Ids and Account Ids
        List<Contact> vpSalesContacts = [SELECT Id, AccountId, Title FROM Contact WHERE Title = 'VP Sales' AND AccountId = :accIds];
        
        //Map of Account Id and Primary Contact Id to be used in setting the Primary contact Id on Oppo
        Map<Id,Id> accIdContactId = new Map<Id,Id>();
        
        //loop through the contacts to create the map of Account Id, Contact Id
        for (Contact con : vpSalesContacts){
            accIdContactId.put(con.AccountId, con.Id);
        }

        //loop through opps to set the primary contact Id using the Account Id, Contact Id map
        for (Opportunity opp : oppNewMap.values()){            
            
            if (opp.Primary_Contact__c == null){
                Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
                oppToUpdate.Primary_Contact__c = accIdContactId.get(opp.AccountId);
                oppMap.put(opp.Id, oppToUpdate);
            }
        }
        update oppMap.values();
    }

}