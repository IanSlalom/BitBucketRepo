<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Deactivate_Discount</fullName>
        <description>Deactivate the discount</description>
        <field>Active__c</field>
        <literalValue>0</literalValue>
        <name>Deactivate Discount</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Discount Ends</fullName>
        <active>true</active>
        <description>Deactivate the discount at the end of the promotion date.</description>
        <formula>true</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Deactivate_Discount</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Discount__c.Promotion_End__c</offsetFromField>
            <timeLength>1</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
</Workflow>
