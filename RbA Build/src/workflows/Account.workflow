<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Account_Name</fullName>
        <field>Name</field>
        <formula>ShippingPostalCode + &quot;, &quot; +  ShippingStreet</formula>
        <name>Set Account Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Inactive_Date</fullName>
        <field>Inactive_Date__c</field>
        <formula>IF( 
AND( 
ISBLANK( Auto_Liab_Expire_Date__c ), 
ISBLANK( General_Liab_Expire_Date__c ), 
ISBLANK( WorkComp_EmplLiab_ExpireDate__c ) 
), 
NULL, 
TODAY()- 
MAX( 
TODAY()- BLANKVALUE(Auto_Liab_Expire_Date__c, DATE(2999, 01, 01)), 
TODAY()- BLANKVALUE(General_Liab_Expire_Date__c, DATE(2999, 01, 01)), 
TODAY()- BLANKVALUE(WorkComp_EmplLiab_ExpireDate__c, DATE(2999, 01, 01)) 
) 
)</formula>
        <name>Set Inactive Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set Account Name</fullName>
        <actions>
            <name>Set_Account_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Account.RecordTypeId</field>
            <operation>equals</operation>
            <value>Dwelling</value>
        </criteriaItems>
        <description>Postal Code, Street Address</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set Inactive Date</fullName>
        <actions>
            <name>Set_Inactive_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Insurance Expiration Date for Vendors</description>
        <formula>OR(ISCHANGED( Auto_Liab_Expire_Date__c ),ISCHANGED(  General_Liab_Expire_Date__c  ),ISCHANGED(  WorkComp_EmplLiab_ExpireDate__c))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
