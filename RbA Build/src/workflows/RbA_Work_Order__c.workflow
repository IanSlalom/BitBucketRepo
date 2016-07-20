<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Last_Renovate_Right_Date_Notification</fullName>
        <description>Last Renovate Right Date Notification</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>RbA_Email_Templates/LastRenovateRightDateNotification</template>
    </alerts>
    <alerts>
        <fullName>PaintStainVendorFollowUp</fullName>
        <description>PaintStainVendorFollowUp</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>RbA_Email_Templates/PaintStainInstallReminder</template>
    </alerts>
    <fieldUpdates>
        <fullName>Set_Account_City</fullName>
        <field>City__c</field>
        <formula>Account__r.ShippingCity</formula>
        <name>Set Account City</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Account_Country</fullName>
        <field>Country__c</field>
        <formula>Account__r.ShippingCountry</formula>
        <name>Set Account Country</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Account_State</fullName>
        <field>State__c</field>
        <formula>Account__r.ShippingState</formula>
        <name>Set Account State</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Account_Street</fullName>
        <field>Street__c</field>
        <formula>Account__r.ShippingStreet</formula>
        <name>Set Account Street</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Account_Zip</fullName>
        <field>Zip__c</field>
        <formula>Account__r.ShippingPostalCode</formula>
        <name>Set Account Zip</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Appointment_Duration_1_hour</fullName>
        <description>Set Appointment Duration to 1</description>
        <field>Appointment_Duration__c</field>
        <formula>1</formula>
        <name>Set Appointment Duration 1 hour</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Appointment_Duration_4_Hours</fullName>
        <description>Set Default Appointment Duration to 4 hours</description>
        <field>Appointment_Duration__c</field>
        <formula>4</formula>
        <name>Set Appointment Duration 4 Hours</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Completed_Date_Install</fullName>
        <field>Completed_Appt_Date_Install__c</field>
        <formula>Today()</formula>
        <name>Set Completed Date - Install</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Completed_Date_Service</fullName>
        <field>Completed_Appt_Date_Service__c</field>
        <formula>Today()</formula>
        <name>Set Completed Date - Service</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Completed_Date_Tech_Measure</fullName>
        <field>Completed_Appt_Date_Tech_Measure__c</field>
        <formula>Today()</formula>
        <name>Set Completed Date - Tech Measure</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Headcount_to_2</fullName>
        <field>Recommended_Crew_Size__c</field>
        <formula>2</formula>
        <name>Set Headcount to 2</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Original_Appt_Date_Time_Install</fullName>
        <field>Original_Appt_Date_Time_Install__c</field>
        <formula>Scheduled_Appt_Date_Time_Install__c</formula>
        <name>Set Original Appt Date/Time - Install</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Original_Appt_Date_Time_Service</fullName>
        <field>Original_Appt_Date_Time_Service__c</field>
        <formula>Scheduled_Appt_Date_Time_Service__c</formula>
        <name>Set Original Appt Date/Time - Service</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Original_Appt_Date_Time_Tech_Measu</fullName>
        <field>Original_Appt_Date_Time_Tech_Measure__c</field>
        <formula>Scheduled_Appt_Date_Time_Tech_Measure__c</formula>
        <name>Set Original Appt Date/Time - Tech Measu</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_WO_Status_Pending_Assignment</fullName>
        <field>Work_Order_Status__c</field>
        <literalValue>Pending Assignment</literalValue>
        <name>Set WO Status Pending Assignment</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_WO_Status_Scheduled_Assigned</fullName>
        <field>Work_Order_Status__c</field>
        <literalValue>Scheduled &amp; Assigned</literalValue>
        <name>Set WO Status Scheduled &amp; Assigned</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Status_to_To_be_scheduled</fullName>
        <field>Work_Order_Status__c</field>
        <literalValue>To be scheduled</literalValue>
        <name>Update Status to To be scheduled</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Last Renovate Right Date Notification</fullName>
        <actions>
            <name>Last_Renovate_Right_Date_Notification</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>RbA_Work_Order__c.Age__c</field>
            <operation>greaterThan</operation>
            <value>53</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Notify WO Owner of Cancelled Order</fullName>
        <actions>
            <name>Cancelled_Order</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>RbA_Work_Order__c.Work_Order_Status__c</field>
            <operation>equals</operation>
            <value>Cancelled</value>
        </criteriaItems>
        <criteriaItems>
            <field>RbA_Work_Order__c.RecordTypeId</field>
            <operation>equals</operation>
            <value>Actions,Visit</value>
        </criteriaItems>
        <criteriaItems>
            <field>RbA_Work_Order__c.Work_Order_Type__c</field>
            <operation>notEqual</operation>
            <value>Service</value>
        </criteriaItems>
        <description>This order has been Cancelled. Please address any open activities on this work order</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>PaintStainInstallReminder</fullName>
        <active>true</active>
        <criteriaItems>
            <field>RbA_Work_Order__c.Work_Order_Type__c</field>
            <operation>equals</operation>
            <value>Paint/Stain</value>
        </criteriaItems>
        <criteriaItems>
            <field>RbA_Work_Order__c.Work_Order_Status__c</field>
            <operation>notEqual</operation>
            <value>Closed,Cancelled</value>
        </criteriaItems>
        <description>Reminder to the Work Order Owner to follow up with the Paint Stain Vendor.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>PaintStainVendorFollowUp</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>RbA_Work_Order__c.Scheduled_Installation_Date__c</offsetFromField>
            <timeLength>3</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Set Appointment Duration 1 Hour</fullName>
        <actions>
            <name>Set_Appointment_Duration_1_hour</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>RbA_Work_Order__c.Work_Order_Type__c</field>
            <operation>equals</operation>
            <value>Tech Measure,Service</value>
        </criteriaItems>
        <description>Set Appointment Duration for 1 hour for Tech Measure and Service.</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Set Appointment Duration 4 Hours</fullName>
        <actions>
            <name>Set_Appointment_Duration_4_Hours</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>RbA_Work_Order__c.Work_Order_Type__c</field>
            <operation>equals</operation>
            <value>Install</value>
        </criteriaItems>
        <description>Set Appointment Duration for 4 hours for Install</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Set Headcount to 2</fullName>
        <actions>
            <name>Set_Headcount_to_2</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>RbA_Work_Order__c.Work_Order_Type__c</field>
            <operation>equals</operation>
            <value>Install</value>
        </criteriaItems>
        <description>If WO is Install, set Recommended Crew Size (Headcount) to 2</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Set Install WO Completed Date</fullName>
        <actions>
            <name>Set_Completed_Date_Install</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>RbA_Work_Order__c.Work_Order_Type__c</field>
            <operation>equals</operation>
            <value>Install</value>
        </criteriaItems>
        <criteriaItems>
            <field>RbA_Work_Order__c.Work_Order_Status__c</field>
            <operation>equals</operation>
            <value>Appt Complete / Closed</value>
        </criteriaItems>
        <description>When the appoitment has been completed and work order has been closed this will update Completed Appt Date/Time: Install</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Set Original Appt Date%2FTime - Install</fullName>
        <actions>
            <name>Set_Original_Appt_Date_Time_Install</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>RbA_Work_Order__c.Scheduled_Appt_Date_Time_Install__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Set Original Appt Date%2FTime - Service</fullName>
        <actions>
            <name>Set_Original_Appt_Date_Time_Service</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>RbA_Work_Order__c.Scheduled_Appt_Date_Time_Service__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Set Original Appt Date%2FTime - Tech Measure</fullName>
        <actions>
            <name>Set_Original_Appt_Date_Time_Tech_Measu</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>RbA_Work_Order__c.Scheduled_Appt_Date_Time_Tech_Measure__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Set Service WO Completed Date</fullName>
        <actions>
            <name>Set_Completed_Date_Service</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>RbA_Work_Order__c.Work_Order_Type__c</field>
            <operation>equals</operation>
            <value>Service</value>
        </criteriaItems>
        <criteriaItems>
            <field>RbA_Work_Order__c.Work_Order_Status__c</field>
            <operation>equals</operation>
            <value>Appt Complete / Closed</value>
        </criteriaItems>
        <description>When the appoitment has been completed and work order has been closed this will update Completed Appt Date/Time: Service</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Set Status Pending Assignment</fullName>
        <actions>
            <name>Set_WO_Status_Pending_Assignment</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>RbA_Work_Order__c.Work_Order_Type__c</field>
            <operation>equals</operation>
            <value>Tech Measure,Install,Service</value>
        </criteriaItems>
        <criteriaItems>
            <field>RbA_Work_Order__c.Work_Order_Status__c</field>
            <operation>equals</operation>
            <value>To be scheduled</value>
        </criteriaItems>
        <criteriaItems>
            <field>RbA_Work_Order__c.Appointment_Date__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>RbA_Work_Order__c.Appointment_Start_Time__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Set Status Scheduled %26 Assigned</fullName>
        <actions>
            <name>Set_WO_Status_Scheduled_Assigned</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>RbA_Work_Order__c.Work_Order_Type__c</field>
            <operation>equals</operation>
            <value>Tech Measure,Install,Service</value>
        </criteriaItems>
        <criteriaItems>
            <field>RbA_Work_Order__c.Work_Order_Status__c</field>
            <operation>equals</operation>
            <value>To be scheduled,Pending Assignment</value>
        </criteriaItems>
        <criteriaItems>
            <field>RbA_Work_Order__c.Number_Open_Events_Formula__c</field>
            <operation>greaterOrEqual</operation>
            <value>1</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Set Tech Measure WO Completed Date</fullName>
        <actions>
            <name>Set_Completed_Date_Tech_Measure</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>RbA_Work_Order__c.Work_Order_Type__c</field>
            <operation>equals</operation>
            <value>Tech Measure</value>
        </criteriaItems>
        <criteriaItems>
            <field>RbA_Work_Order__c.Work_Order_Status__c</field>
            <operation>equals</operation>
            <value>Appt Complete / Closed</value>
        </criteriaItems>
        <description>When the appoitment has been completed and work order has been closed this will update Completed Appt Date/Time: Tech Measure</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Update WO Status%3A To be scheduled</fullName>
        <actions>
            <name>Update_Status_to_To_be_scheduled</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>When a WO is cancelled the status needs to be changed to &quot;to be scheduled&quot;</description>
        <formula>OR( ISCHANGED(Cancel_Date__c), ISCHANGED ( Cancel_Reason__c ) )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <tasks>
        <fullName>Cancelled_Order</fullName>
        <assignedToType>owner</assignedToType>
        <description>This order has been Cancelled. Please address any open activities on this work order</description>
        <dueDateOffset>1</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Open</status>
        <subject>Cancelled Order</subject>
    </tasks>
</Workflow>
