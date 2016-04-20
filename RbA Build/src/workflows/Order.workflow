<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Order_Cancellation_In_Progress</fullName>
        <description>Order Cancellation In Progress</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>DefaultWorkflowUser</senderType>
        <template>Backoffice_Email_Templates/Order_Cancellation_In_Progress</template>
    </alerts>
    <fieldUpdates>
        <fullName>Set_Status_to_Closed</fullName>
        <field>Status</field>
        <literalValue>Closed</literalValue>
        <name>Set Status to Closed</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Order Cancellation In Progress</fullName>
        <actions>
            <name>Order_Cancellation_In_Progress</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Complete_Cancellation_Tasks_for_Order</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Order.Status</field>
            <operation>equals</operation>
            <value>Cancellation in Progress</value>
        </criteriaItems>
        <description>Fires when an order is set to cancellation in progress</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set Status to Closed</fullName>
        <actions>
            <name>Set_Status_to_Closed</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Order.Service_Type__c</field>
            <operation>equals</operation>
            <value>Save</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <tasks>
        <fullName>Complete_Cancellation_Tasks_for_Order</fullName>
        <assignedToType>owner</assignedToType>
        <description>Please cancel all activities and cancel this order.</description>
        <dueDateOffset>3</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Open</status>
        <subject>Complete Cancellation Tasks for Order</subject>
    </tasks>
</Workflow>