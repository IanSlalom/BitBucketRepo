<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Purchase_Order_Ship_Date_Change</fullName>
        <description>Purchase Order Ship Date Change</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>DefaultWorkflowUser</senderType>
        <template>Backoffice_Email_Templates/Purchase_Order_Ship_Date_Change</template>
    </alerts>
    <fieldUpdates>
        <fullName>Set_PO_Number</fullName>
        <description>Uses an auto-number and the abbreviation field on the PO to create the PO Name.</description>
        <field>Name</field>
        <formula>IF( ISBLANK(Store_Abbreviation__c), &apos;XX&apos;, Store_Abbreviation__c) &amp;  
&apos;-&apos; &amp;
PO_System_Number__c</formula>
        <name>Set PO Number</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Purchase Order Created</fullName>
        <actions>
            <name>Set_PO_Number</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Fires every time a po is created.</description>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Purchase Order Ship Date Change</fullName>
        <actions>
            <name>Purchase_Order_Ship_Date_Change</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Estimated_Ship_Date_Has_Changed</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <description>Fires when a purchase order&apos;s estimated ship date has changed</description>
        <formula>AND( ISCHANGED( Estimated_Ship_Date__c ),        NOT(ISBLANK(PRIORVALUE(Estimated_Ship_Date__c ))) )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <tasks>
        <fullName>Estimated_Ship_Date_Has_Changed</fullName>
        <assignedToType>owner</assignedToType>
        <description>This purchase order&apos;s estimated ship date has changed. Please take any actions as necessary.</description>
        <dueDateOffset>3</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Open</status>
        <subject>Estimated Ship Date Has Changed</subject>
    </tasks>
</Workflow>
