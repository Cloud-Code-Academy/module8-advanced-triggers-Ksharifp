public with sharing class OpportunityTriggerHandler {
    
    //Before Insert
    public static void setDefaultType(List<Opportunity> opps) {

        //CRUD Validation 
        if (!Schema.sObjectType.Opportunity.isUpdateable()) {
            throw new System.SecurityException('You do not have permission to update Opportunity records.');
        }

        if (!Schema.sObjectType.Opportunity.fields.Type.isUpdateable()) {
            throw new System.SecurityException('You do not have access to update the Type field on Opportunity.');
        }

        for (Opportunity opp : opps){
            if (opp.Type == null){
                opp.Type = 'New Customer'; 
            }
        }
    }
    
    //Before Update Amount More than 5000
    public static void preventUpdateWrongAmount (List<Opportunity> opps){
        //CRUD Validation 
        if (!Schema.sObjectType.Opportunity.isUpdateable()) {
            throw new System.SecurityException('You do not have permission to update Opportunity records.');
        }

        if (!Schema.sObjectType.Opportunity.fields.Amount.isUpdateable()) {
            throw new System.SecurityException('You do not have access to update the Type field on Opportunity.');
        }

        for(Opportunity opp : opps){
            if (opp.Amount < 5000) {
                opp.addError('Opportunity amount must be greater than 5000');
            }
        }
    }


    //Before Delete Closed Won Banking Industry
    public static void dontDeleteClosedOpps(List<Opportunity> opps){
        //CRUD Validation
        if (!Schema.sObjectType.Opportunity.isAccessible()) {
            throw new System.SecurityException('You do not have permission to update Opportunity records.');
        }

        Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Industry FROM Account WHERE Id IN (SELECT AccountId FROM Opportunity WHERE Id IN :opps)]);
        for(Opportunity opp : opps){
            if(opp.StageName == 'Closed Won'){
                if(accounts.get(opp.AccountId).Industry == 'Banking'){
                    opp.addError('Cannot delete a closed won opportunity for a banking account');
                }
            }
        }
    }
    


    //After Insert
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

        List<Task> tasksToCreate = new List<Task>();

            for (Opportunity opp : opps){
                Task tsk = new Task();
                tsk.Subject = 'Call Primary Contact';
                tsk.WhatId = opp.Id;
                tsk.WhoId = opp.Primary_Contact__c;
                tsk.OwnerId = opp.OwnerId;
                tsk.ActivityDate = Date.today().addDays(3);
                tasksToCreate.add(tsk);
                //insert tsk();
            }
            insert tasksToCreate;
    }

    //After Update
    /**
     * Updates the Description field of Opportunities with the stage change.
     * If the StageName is not null and the Description is null, appends the stage change
     * information along with the current timestamp to the Description field.
     */
    public static void updateDescriptionStage (List<Opportunity> opps){
         //CRUD Validation
        if (!Schema.sObjectType.Opportunity.isUpdateable()) {
            throw new System.SecurityException('You do not have permission to update Opportunity records.');
        }

        if (!Schema.sObjectType.Opportunity.fields.StageName.isAccessible()){
            throw new System.SecurityException('You do not have permission to update the Description field Opportunity records.');
        }

        if (!Schema.sObjectType.Opportunity.fields.Description.isUpdateable()){
            throw new System.SecurityException('You do not have permission to update the Description field Opportunity records.');
        }

        Set<Id> oppIds = new Set<Id>();
        if (!opps.isEmpty()) {
            for (Opportunity opp : opps) {
            oppIds.add(opp.Id);
            }
        }
        
        List<Opportunity> oppsToUpdate = [SELECT Id, StageName, Description FROM Opportunity WHERE Id IN :oppIds];
        if (!oppsToUpdate.isEmpty()) {
            for (Opportunity oppo : oppsToUpdate){
                if (oppo.StageName != null) {
                    oppo.Description = (oppo.Description == null ? '' : oppo.Description) +'\n Stage Change:' + oppo.StageName + ':' + Datetime.now().format();
                } 
            } 
        }
    }
    
    //After Update
    public static void setCEOPrimaryContact(List<Opportunity> opps){
        
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

        Set<Id> accountIds = new Set<Id>();
        for(Opportunity opp : opps){
            accountIds.add(opp.AccountId);
        }
        
        Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, FirstName, AccountId FROM Contact WHERE AccountId IN :accountIds AND Title = 'CEO' ORDER BY FirstName ASC]);
        Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();

        for (Contact cont : contacts.values()) {
            if (!accountIdToContact.containsKey(cont.AccountId)) {
                accountIdToContact.put(cont.AccountId, cont);
            }
        }

        for(Opportunity opp : opps){
            if(opp.Primary_Contact__c == null){
                if (accountIdToContact.containsKey(opp.AccountId)){
                    opp.Primary_Contact__c = accountIdToContact.get(opp.AccountId).Id;
                }
            }
        }
    }


    //After Delete Notify Oppo Owner
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

        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        //created a set of owner Ids from the opps collection (the dot notation at the end of the soql was a cool trick)
        Set<Id> ownerIds = new Set<Id> {[SELECT OwnerId FROM Opportunity WHERE Id = :opps].OwnerId};
        //created a string of emails using the set of Ids
        String[] toAddresses = new String[] {[SELECT Id, Email FROM User WHERE Id = :ownerIds].Email};
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

    //After Undelete Set VPSales as Primary Contact
    public static void setVPPrimaryContact(Map<Id,Opportunity> oppNewMap) {
        
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

        
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        Set<Id> accIds = new Set<Id> {[SELECT AccountId FROM Opportunity WHERE Id = :oppNewMap.keySet()].AccountId};
        List<Contact> vpSalesContacts = [SELECT Id, AccountId, Title FROM Contact WHERE Title = 'VP Sales' AND AccountId = :accIds];
        Map<Id,Id> accIdContactId = new Map<Id,Id>();

        for (Contact con : vpSalesContacts){
            accIdContactId.put(con.AccountId, con.Id);
        }

        for (Opportunity opp : oppNewMap.values()){            
        
            if (opp.Primary_Contact__c == null){
                Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
                oppToUpdate.Primary_Contact__c = accIdContactId.get(opp.AccountId);
                oppMap.put(opp.Id, oppToUpdate);
            }
        }
        update oppMap.values();
    }

    public static void validateAmount(List<Opportunity> opps){
        for(Opportunity opp : opps){
            if(opp.Amount < 5000){
                opp.addError('Opportunity amount must be greater than 5000');
            }
        }
    }

    public static void preventDeleteClosedWon(List<Opportunity> opps){
        //Account related to the opportunities 
        Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Industry FROM Account WHERE Id IN (SELECT AccountId FROM Opportunity WHERE Id IN :opps)]);
        for(Opportunity opp : opps){
            if(opp.StageName == 'Closed Won'){
                if(accounts.get(opp.AccountId).Industry == 'Banking'){
                    opp.addError('Cannot delete a closed won opportunity for a banking account');
                }
            }
        }
    }



    /*public static void setCEOPrimaryContact(List<Opportunity> opps){
        //Get contacts related to the opportunity account
        Set<Id> accountIds = new Set<Id>();
        for(Opportunity opp : opps){
            accountIds.add(opp.AccountId);
        }
        
        Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, FirstName, AccountId FROM Contact WHERE AccountId IN :accountIds AND Title = 'CEO' ORDER BY FirstName ASC]);
        Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();

        for (Contact cont : contacts.values()) {
            if (!accountIdToContact.containsKey(cont.AccountId)) {
                accountIdToContact.put(cont.AccountId, cont);
            }
        }

        for(Opportunity opp : opps){
            if(opp.Primary_Contact__c == null){
                if (accountIdToContact.containsKey(opp.AccountId)){
                    opp.Primary_Contact__c = accountIdToContact.get(opp.AccountId).Id;
                }
            }
        }
    }*/
    

}