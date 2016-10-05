<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_Billing_City</fullName>
        <description>Pushes Invoice Location City from store configuration to the Billing City of Store Account</description>
        <field>BillingCity</field>
        <formula>Invoice_Location_City__c</formula>
        <name>Update Billing City</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <targetObject>Store__c</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Billing_State</fullName>
        <description>Pushes Invoice Location State from store configuration to the Billing State of Store Account</description>
        <field>BillingState</field>
        <formula>Invoice_Location_State__c</formula>
        <name>Update Billing State</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <targetObject>Store__c</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Billing_Street</fullName>
        <description>Pushes Invoice Location Address from store configuration to the Billing Street of Store Account</description>
        <field>BillingStreet</field>
        <formula>Invoice_Location_Address__c</formula>
        <name>Update Billing Street</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <targetObject>Store__c</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Billing_Zip</fullName>
        <description>Pushes Invoice Location Zip from store configuration to the Billing Zip of Store Account</description>
        <field>BillingPostalCode</field>
        <formula>Invoice_Location_Zip__c</formula>
        <name>Update Billing Zip</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <targetObject>Store__c</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Contractor_License_1</fullName>
        <description>Pushes Contractor License 1 from store configuration to the Store Account</description>
        <field>Contractor_License_1__c</field>
        <formula>Contractor_License_1__c</formula>
        <name>Update Contractor License 1</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <targetObject>Store__c</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Contractor_License_2</fullName>
        <description>Pushes Contractor License 2 from store configuration to the Store Account</description>
        <field>Contractor_License_2__c</field>
        <formula>Contractor_LIcense_2__c</formula>
        <name>Update Contractor License 2</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <targetObject>Store__c</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_DBA</fullName>
        <description>Pushes DBA from store configuration to the Store Account</description>
        <field>DBA__c</field>
        <formula>DBA__c</formula>
        <name>Update DBA</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <targetObject>Store__c</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Fax</fullName>
        <description>Pushes fax from store configuration to the Store Account</description>
        <field>Fax</field>
        <formula>Fax__c</formula>
        <name>Update Fax</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <targetObject>Store__c</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Phone</fullName>
        <description>Pushes phone number from store configuration to the Store Account</description>
        <field>Phone</field>
        <formula>Phone__c</formula>
        <name>Update Phone</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <targetObject>Store__c</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Shipping_City</fullName>
        <description>Pushes Invoice Location City from store configuration to the Shipping City of Store Account</description>
        <field>ShippingCity</field>
        <formula>Invoice_Location_City__c</formula>
        <name>Update Shipping City</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <targetObject>Store__c</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Shipping_State</fullName>
        <description>Pushes Invoice Location State from store configuration to the Shipping State of Store Account</description>
        <field>ShippingState</field>
        <formula>Invoice_Location_State__c</formula>
        <name>Update Shipping State</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <targetObject>Store__c</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Shipping_Street</fullName>
        <description>Pushes Invoice Location Address from store configuration to the Shipping Street of Store Account</description>
        <field>ShippingStreet</field>
        <formula>Invoice_Location_Address__c</formula>
        <name>Update Shipping Street</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <targetObject>Store__c</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Shipping_Zip</fullName>
        <description>Pushes Invoice Location Zip from store configuration to the Shipping Zip of Store Account</description>
        <field>ShippingPostalCode</field>
        <formula>Invoice_Location_Zip__c</formula>
        <name>Update Shipping Zip</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <targetObject>Store__c</targetObject>
    </fieldUpdates>
    <rules>
        <fullName>Store Config Update 1</fullName>
        <actions>
            <name>Update_Contractor_License_1</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Contractor_License_2</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_DBA</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Fax</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Phone</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Store Config Update 2</fullName>
        <actions>
            <name>Update_Billing_City</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Billing_State</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Billing_Street</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Billing_Zip</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Shipping_City</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Shipping_State</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Shipping_Street</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Shipping_Zip</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
