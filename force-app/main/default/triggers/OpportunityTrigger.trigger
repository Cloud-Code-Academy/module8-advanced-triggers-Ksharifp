/*
OpportunityTrigger Overview

This class defines the trigger logic for the Opportunity object in Salesforce. It focuses on three main functionalities:
1. Ensuring that the Opportunity amount is greater than $5000 on update.
2. Preventing the deletion of a 'Closed Won' Opportunity if the related Account's industry is 'Banking'.
3. Setting the primary contact on an Opportunity to the Contact with the title 'CEO' when updating.

Usage Instructions:
For this lesson, students have two options:
1. Use the provided `OpportunityTrigger` class as is.
2. Use the `OpportunityTrigger` from you created in previous lessons. If opting for this, students should:
    a. Copy over the code from the previous lesson's `OpportunityTrigger` into this file.
    b. Save and deploy the updated file into their Salesforce org.

Remember, whichever option you choose, ensure that the trigger is activated and tested to validate its functionality.
*/
trigger OpportunityTrigger on Opportunity (before insert, after insert, before update, after update, before delete, after delete, after undelete) {

    /*
    * Opportunity Trigger
    * When an opportunity is updated validate that the amount is greater than 5000.
    * Trigger should only fire on update.
    */

    /*
    * Opportunity Trigger
    * When an opportunity is deleted prevent the deletion of a closed won opportunity if the account industry is 'Banking'.
    * Trigger should only fire on delete.
    */

    /*
    * Opportunity Trigger
    * When an opportunity is updated set the primary contact on the opportunity to the contact with the title of 'CEO'.
    * Trigger should only fire on update.
    */
  
    //--------------------------------

    if (Trigger.isBefore && Trigger.isInsert){
        // Set default Type for new Opportunities
        OpportunityTriggerHandler.setDefaultType(Trigger.new);  
    } 
    
    if (Trigger.isBefore && Trigger.isUpdate) {
        OpportunityTriggerHandler.updateDescriptionStage(Trigger.new, Trigger.oldMap);
        OpportunityTriggerHandler.preventUpdateWrongAmount(Trigger.new);
        OpportunityTriggerHandler.setCEOPrimaryContact(Trigger.new);
        
    }    

    if (Trigger.isBefore && Trigger.isDelete){
        // Prevent deletion of closed Opportunities
        //OpportunityTriggerHandler.preventDeleteClosedWon(Trigger.old);
        OpportunityTriggerHandler.dontDeleteClosedOpps(Trigger.old);
    }

    //if (Trigger.isBefore && Trigger.isUndelete) {
        //OpportunityTriggerHandler.setVPPrimaryContact(Trigger.new, Trigger.oldMap);
    //}
    

    
    if (Trigger.isAfter){
        if (Trigger.isInsert){
            // Create a new Task for newly inserted Opportunities
            // created a new list to bulkify the creation of the tasks
            OpportunityTriggerHandler.createTasks(Trigger.new);
        } 

        //if (Trigger.isUpdate){
            // Append Stage changes in Opportunity Description
            
        //}

        // Send email notifications when an Opportunity is deleted 
        if (Trigger.isDelete){
            OpportunityTriggerHandler.notifyOwnersOpportunityDeleted(Trigger.old);
        } 


        // Assign the primary contact to undeleted Opportunities
        if (Trigger.isUndelete){
            OpportunityTriggerHandler.setVPPrimaryContact(Trigger.new);
        }
        
    }

    /*
    notifyOwnersOpportunityDeleted:
    - Sends an email notification to the owner of the Opportunity when it gets deleted.
    - Uses Salesforce's Messaging.SingleEmailMessage to send the email.
    */


    /*
    assignPrimaryContact:
    - Assigns a primary contact with the title of 'VP Sales' to undeleted Opportunities.
    - Only updates the Opportunities that don't already have a primary contact.
    */
}