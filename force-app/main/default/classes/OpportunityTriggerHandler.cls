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
            if (opp.Type == null) {
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

        //created a map to connect the opp id and the account industry
        Map<Id, String> oppIdAccIndustry = new Map<Id, String>();
        for (Opportunity opp : opps) {
            oppIdAccIndustry.put(opp.Id, opp.Account.Industry);
        }

        //go through deleted opps to check account industry
        for (Opportunity opp : opps){
            
            if(opp.StageName == 'Closed Won' && oppIdAccIndustry.get(opp.Id) == 'Banking'){
                opp.addError('Cannot delete closed opportunity');
            } else if (opp.StageName == 'Closed Won' || opp.StageName == 'Closed Lost') {
                opp.addError('Cannot delete closed opportunity');
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

    //After Update --> changed to before update
    /**
     * Updates the Description field of Opportunities with the stage change.
     * If the StageName is not null and the Description is null, appends the stage change
     * information along with the current timestamp to the Description field.
     */
    public static void updateDescriptionStage (List<Opportunity> opps, Map<Id, Opportunity> oldMap){
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

        for (Opportunity opp : opps){
            Opportunity oldOpp = oldMap.get(opp.Id);
            if (opp.StageName != null && oldOpp != null && opp.StageName != oldOpp.StageName) {
                opp.Description = (opp.Description == null ? '' : opp.Description) +'\n Stage Change:' + opp.StageName + ':' + Datetime.now().format();
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
            throw new System.SecurityException('You do not have access to the PrimaryContact field on Opportunity.');
        }
        
        if (!Schema.sObjectType.Account.isAccessible()) {
            throw new System.SecurityException('You do not have permission to read Account records.');
        }

        //if (!Schema.sObjectType.Account.fields.Primary_Contact__c.isAccessible()) {
            //throw new System.SecurityException('You do not have access to the PrimaryContact field on Account.');
        //} commenting this out because it is giving an error when committing

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
        
        List<Contact> ceoContacts = [SELECT Id, FirstName, AccountId FROM Contact WHERE AccountId IN :accountIds AND Title = 'CEO' ORDER BY FirstName ASC];
        Map<Id, Id> accountIdToContact = new Map<Id, Id>();

        if (!ceoContacts.isEmpty()) {
            for (Contact con : ceoContacts) {
                accountIdToContact.put(con.AccountId, con.Id);
            }
        }
        
        for(Opportunity opp : opps){
            if(opp.Primary_Contact__c == null){
                if (accountIdToContact.containsKey(opp.AccountId)){
                    opp.Primary_Contact__c = accountIdToContact.get(opp.AccountId);
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
        Set<Id> ownerIds = new Set<Id>();
        for (Opportunity opp : opps) {
            ownerIds.add(opp.OwnerId);
        }

        //created a string of emails using the set of Ids
        Set<String> toAddresses = new Set<String>();
        List<User> ownerUsers = new List<User>([SELECT Id, Email FROM User WHERE Id IN :ownerIds]);
        for (User u : ownerUsers) {
            if (!ownerUsers.isEmpty() && u.Email != null) {
                toAddresses.add(u.Email);
            }
        }

        if (!toAddresses.isEmpty()) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>(toAddresses));
            mail.setSubject('Opportunity Deleted');
            mail.setPlainTextBody('Your Opportunity has been deleted.');
            mails.add(mail);
        }   
        
        try {
            Messaging.sendEmail(mails);
        } catch (Exception e){
            //left blank because System.debug was getting an error when tried to commit
        }
    }

    //After Undelete Set VPSales as Primary Contact
    public static void setVPPrimaryContact(List<Opportunity> opps) {
        // the old records of undelete do not exist
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

        //if (!Schema.sObjectType.Account.fields.Primary_Contact__c.isAccessible()) {
            //throw new System.SecurityException('You do not have access to the AccountId field on Account.');
        //} commented this validation out because it was causing issues when committing

        if (!Schema.sObjectType.Contact.isAccessible()) {
            throw new System.SecurityException('You do not have permission to read Contact records.');
        }

        if (!Schema.sObjectType.Contact.fields.Id.isAccessible()) {
            throw new System.SecurityException('You do not have access to the Id field on Contact.');
        }

        //map of opps to be updated
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();

        //set of account Ids to be used in getting the primary contact
        Set<Id> accIds = new Set<Id>();
        for (Opportunity opp : opps) {
            if (opp.AccountId != null) {
                accIds.add(opp.AccountId);
            }
        }
        
        //list of contacts with the title of VP Sales to be associated with Account Id
        List<Contact> vpSalesContacts = [SELECT Id, AccountId, Title FROM Contact WHERE Title = 'VP Sales' AND AccountId = :accIds];
        
        //map of the account Id and VPSalesContact Id to be used in updating the opportunity
        Map<Id,Id> accIdContactId = new Map<Id,Id>();
        for (Contact con : vpSalesContacts){
            if (con.AccountId != null) {
                accIdContactId.put(con.AccountId, con.Id);
            }           
        }
        
        //going through newly updated records, 
        for (Opportunity opp : opps){
            if (opp.AccountId == null) {
                continue;
            } 
            
            //if (oppOldMap != null && oppOldMap.keySet().contains(opp.Id)) {
                //Opportunity oldOpp = oppOldMap.get(opp.Id);
                //if (oldOpp != null) {
                    //if ( opp.IsDeleted == FALSE && oldOpp.IsDeleted == TRUE) {
            if (opp.Primary_Contact__c == null){
                Id vpContactId = accIdContactId.get(opp.AccountId);
                if (vpContactId != null) {
                    //In case this method must have been used in an After Undelete context
                    Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
                    oppToUpdate.Primary_Contact__c = vpContactId;
                    //In case this method must have been used in an After Undelete context
                    oppMap.put(opp.Id, oppToUpdate);
                }
            }
                    //}
                //} 
            //} 
        } 
        // In case it is required to use this method in After Undelete
        if (!oppMap.isEmpty()) {
            update oppMap.values();
        }
        
    }

    

    //public static void validateAmount(List<Opportunity> opps){
        //for(Opportunity opp : opps){
           // if(opp.Amount < 5000){
             //   opp.addError('Opportunity amount must be greater than 5000');
           // }
        //}
    //}

 



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