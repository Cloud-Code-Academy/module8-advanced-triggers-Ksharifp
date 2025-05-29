public with sharing class OpportunityHelper {

    public static void setDefaultType(List<Opportunity> opps) {
        for (Opportunity opp : opps){
            if (opp.Type == null){
                opp.Type = 'New Customer'; 
            }
        }
    }

    public static void dontDeleteClosedOpps(List<Opportunity> opps){
        for (Opportunity oldOpp : opps){
            if (oldOpp.IsClosed){
                oldOpp.addError('Cannot delete closed opportunity');
            }
        }
    }

    public static void createTasks(List<Opportunity> opps){
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

    public static void updateDescriptionStage (List<Opportunity> opps){
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Opportunity opp : opps){
                if (opp.StageName != null) {
                    opp.Description += '\n Stage Change:' + Opp.StageName + ':' + Datetime.now().format();
                    oppsToUpdate.add(opp);
                }
            }
        update oppsToUpdate;
    }


    public static void notifyOwnersOpportunityDeleted(List<Opportunity> opps) {
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


    public static void assignPrimaryContact(Map<Id,Opportunity> oppNewMap) {        
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        Set<Id> accIds = new Set<Id> {[SELECT AccountId FROM Opportunity WHERE Id = :oppNewMap.keySet()].AccountId};
        List<Contact> vpSalesContacts = [SELECT Id, AccountId, Title FROM Contact WHERE Title = 'VP Sales' AND AccountId = :accIds];
        Map<Id,Id> accIdContactId = new Map<Id,Id>();
        for (Contact con : vpSalesContacts){
            accIdContactId.put(con.AccountId, con.Id);
        }
        for (Opportunity opp : oppNewMap.values()){            
            //Contact primaryContact = [SELECT Id, AccountId FROM Contact WHERE Title = 'VP Sales' AND AccountId = :opp.AccountId LIMIT 1];
            if (opp.Primary_Contact__c == null){
                Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
                oppToUpdate.Primary_Contact__c = accIdContactId.get(opp.AccountId);
                oppMap.put(opp.Id, oppToUpdate);
            }
        }
        update oppMap.values();
    }

}