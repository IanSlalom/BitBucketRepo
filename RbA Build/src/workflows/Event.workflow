<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Close_Event</fullName>
        <field>Closed_Event__c</field>
        <literalValue>1</literalValue>
        <name>Close Event</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Original_Start_Date</fullName>
        <field>Original_Start_Date__c</field>
        <formula>ActivityDateTime</formula>
        <name>Set Original Start Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set Original Start Date</fullName>
        <actions>
            <name>Set_Original_Start_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Event.Type</field>
            <operation>equals</operation>
            <value>Tech Measure,Service,Install</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Update Closed Event</fullName>
        <active>true</active>
        <criteriaItems>
            <field>Event.EndDateTime</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>Used to trigger roll up</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Close_Event</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Event.End_Date_Time_Minus_1_Hour__c</offsetFromField>
            <timeLength>1</timeLength>
            <workflowTimeTriggerUnit>Hours</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
</Workflow>
