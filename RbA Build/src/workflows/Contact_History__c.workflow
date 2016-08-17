<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Unique_Name_for_Contact_History</fullName>
        <description>Field Update for setting Unique Name field on Contact History. (Cur or Pas) + DwellingId + ContactId</description>
        <field>Unique_Contact_History__c</field>
        <formula>LEFT(TEXT(Type__c), 3)&amp; Dwelling__r.Id &amp; Contact__r.Id</formula>
        <name>Set Unique Name for Contact History</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Unique Contact History Record</fullName>
        <actions>
            <name>Set_Unique_Name_for_Contact_History</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Creates a concatenation of Type,Dwelling, and Contact to ensure no two Contact History records are the same</description>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
