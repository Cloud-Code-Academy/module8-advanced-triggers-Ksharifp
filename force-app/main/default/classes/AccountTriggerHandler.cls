Public with sharing class AccountTriggerHandler {

        //A method to change the account type to 'Prospect'(before insert)
        //A method to copy the shipping address to the billing address.(before insert and update)
        //A method to set the rating to 'Hot' if the Phone, Website, and Fax ALL have a value. (before insert and update)
        //A method to create a contact related to the account with the following default values:(after insert)


        // Validating CRUD


        
    Public static void beforeInsertSetType (List<Account> newAccounts) {
        
        //Going through new accounts without Type to set the Type field values
        
        for(Account acc: newAccounts) {

            if (acc.Type == null) {
                acc.Type = 'Prospect';
            }

        }

    }


    Public static void beforeInsertUpdateAddressCopy (List<Account> newAccounts) {
        
        //Going through new accounts without Type to set the Billing Address field values

        for(Account acc : newAccounts) {

            //if (acc.ShippingAddress != null) {
                acc.BillingStreet = acc.ShippingStreet;
                acc.BillingCity = acc.ShippingCity;
                acc.BillingState = acc.ShippingState;
                acc.BillingCountry = acc.ShippingCountry;
                acc.BillingPostalCode = acc.ShippingPostalCode;
            //}

        }
        
    }


    Public static void beforeInsertUpdateRating (List<Account> newAccounts) {
        
        //Going through new accounts without Type to set the Rating field values
        for(Account acc: newAccounts) {

            if (acc.Fax != null && acc.Phone != null && acc.Website != null) {
                acc.Rating = 'Hot';

            }

        }

    }


    Public static void afterInsertContactCreate (List<Account> newAccounts) {

        // Validate CRUD permissions for inserting Contact
        if (!Schema.sObjectType.Contact.isCreateable()) {
            throw new System.SecurityException('You do not have permission to create Contact records.');
        }
                
        // Validate CRUD permission for insering Contact fields
        if (!Schema.sObjectType.Contact.fields.LastName.isAccessible() || 
            !Schema.sObjectType.Contact.fields.AccountId.isAccessible() ||
            !Schema.sObjectType.Contact.fields.Email.isAccessible() ||
            !Schema.sObjectType.Contact.fields.Id.isAccessible()) {
            throw new System.SecurityException('You do not have access to one or more fields on Contact.');
        }

        List<Contact> relatedContacts = new List<Contact>();

        //Going through all new accounts to create related contacts

        for (Account acc : newAccounts) {
            //this was a short line of code I found on the help docs.

            relatedContacts.add(new Contact(LastName = 'DefaultContact', AccountId = acc.Id, Email = 'default@email.com')); 
        }
        
        insert relatedContacts;
    }
    
}