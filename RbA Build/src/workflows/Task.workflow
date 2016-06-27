<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Record_Type_to_Collections</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Collections</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Set Record Type to Collections</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set Task Record Type to Collections</fullName>
        <actions>
            <name>Set_Record_Type_to_Collections</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Task.Subject</field>
            <operation>contains</operation>
            <value>Collection</value>
        </criteriaItems>
        <description>When a task is created via conga, need to update the record type.  cannot currently set in conga.</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
