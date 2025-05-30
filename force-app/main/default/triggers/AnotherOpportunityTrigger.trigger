/*
AnotherOpportunityTrigger Overview

This trigger was initially created for handling various events on the Opportunity object. It was developed by a prior developer and has since been noted to cause some issues in our org.

IMPORTANT:
- This trigger does not adhere to Salesforce best practices.
- It is essential to review, understand, and refactor this trigger to ensure maintainability, performance, and prevent any inadvertent issues.

ISSUES:
Avoid nested for loop - 1 instance ✓
Avoid DML inside for loop - 1 instance ✓
Bulkify Your Code - 1 instance ✓
Avoid SOQL Query inside for loop - 2 instances ✓
Stop recursion - 1 instance

RESOURCES: 
https://www.salesforceben.com/12-salesforce-apex-best-practices/
https://developer.salesforce.com/blogs/developer-relations/2015/01/apex-best-practices-15-apex-commandments
trigger AnotherOpportunityTrigger on Opportunity (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    if (Trigger.isBefore){
        if (Trigger.isInsert){
            // Set default Type for new Opportunities
            OpportunityTriggerHandler.setDefaultType(Trigger.new);
                
        } else if (Trigger.isDelete){
            // Prevent deletion of closed Opportunities
            OpportunityTriggerHandler.dontDeleteClosedOpps(Trigger.new);
        }
    }

    if (Trigger.isAfter){
        if (Trigger.isInsert){
            // Create a new Task for newly inserted Opportunities
            // created a new list to bulkify the creation of the tasks
            OpportunityTriggerHandler.createTasks(Trigger.new);

        } else if (Trigger.isUpdate){

            // Append Stage changes in Opportunity Description
            OpportunityTriggerHandler.updateDescriptionStage(Trigger.new);
            
        }
        // Send email notifications when an Opportunity is deleted 
        else if (Trigger.isDelete){
            OpportunityTriggerHandler.notifyOwnersOpportunityDeleted(Trigger.old);
        } 
        // Assign the primary contact to undeleted Opportunities
        else if (Trigger.isUndelete){
            OpportunityTriggerHandler.setVPPrimaryContact(Trigger.newMap);
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
    