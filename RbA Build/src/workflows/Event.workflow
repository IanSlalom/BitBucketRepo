<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_End_Date_Time</fullName>
        <field>End_Date_Time_Minus_1_Hour__c</field>
        <formula>ActivityDateTime + ((DurationInMinutes-60)/1440)</formula>
        <name>Set End Date/Time</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Event_Closed</fullName>
        <field>Closed_Event__c</field>
        <literalValue>1</literalValue>
        <name>Set Event Closed</name>
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
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Mark Event Closed</fullName>
        <active>false</active>
        <criteriaItems>
            <field>Event.Type</field>
            <operation>equals</operation>
            <value>Tech Measure,Service,Install</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Set_Event_Closed</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Event.End_Date_Time_Minus_1_Hour__c</offsetFromField>
            <timeLength>1</timeLength>
            <workflowTimeTriggerUnit>Hours</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Set Event Closed</fullName>
        <active>false</active>
        <criteriaItems>
            <field>Event.Open_Event__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Set Event End Date%2FTime</fullName>
        <actions>
            <name>Set_End_Date_Time</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Event.Original_Start_Date__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Set Original Start Date</fullName>
        <actions>
            <name>Set_End_Date_Time</name>
            <type>FieldUpdate</type>
        </actions>
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
</Workflow>
