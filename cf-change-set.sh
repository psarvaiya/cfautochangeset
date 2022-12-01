#!/bin/bash

function quit_execution(){
  print_color 'red' "Script Exited"
  exit

}

function execute_change_set(){
        aws cloudformation execute-change-set  --change-set-name $(cat changeset.name) --stack-name sds-internal-change-sets
        aws cloudformation wait stack-update-complete --stack-name sds-internal-change-sets

}

function get_stack_events(){
        aws cloudformation describe-stack-events --stack-name sds-internal-change-sets  --query StackEvents[*].[Timestamp,LogicalResourceId,ResourceStatus,ResourceStatusReason] --output table

        aws cloudformation describe-stack-events --stack-name sds-internal-change-sets  --query StackEvents[*].[Timestamp,LogicalResourceId,ResourceStatus,ResourceStatusReason] --output table > get_stack_events.txt 
}


function get_change_sets(){
        print_color 'green' "Fetching change sets"
        aws cloudformation  describe-change-set --change-set-name $(cat changeset.name) --stack-name sds-internal-change-sets --query ExecutionStatus --query Changes[*].ResourceChange.[Action,LogicalResourceId,PhysicalResourceId] --output table

        aws cloudformation  describe-change-set --change-set-name $(cat changeset.name) --stack-name sds-internal-change-sets --query ExecutionStatus --query Changes[*].ResourceChange.[Action,LogicalResourceId,PhysicalResourceId] --output table > get_change_sets.txt


}

function list_stack_resources(){
        aws cloudformation list-stack-resources --stack-name sds-internal-change-sets --query StackResourceSummaries[*].[LogicalResourceId,PhysicalResourceId,ResourceType] --output table

        aws cloudformation list-stack-resources --stack-name sds-internal-change-sets --query StackResourceSummaries[*].[LogicalResourceId,PhysicalResourceId,ResourceType] --output table > list_stack_resources.txt

}


function display_output(){
        aws cloudformation describe-stacks --stack-name sds-internal-change-sets --query Stacks[*].Outputs[*] --output table

        aws cloudformation describe-stacks --stack-name sds-internal-change-sets --query Stacks[*].Outputs[*] --output table > output.txt

}


function check_changeset_available(){
        check_available=$(aws cloudformation  describe-change-set --change-set-name $(cat changeset.name) --stack-name sds-internal-change-sets --query ExecutionStatus --output text)

}


function loop_parameters(){
        count_iteration=$(aws cloudformation validate-template --query 'length(Parameters[*].ParameterKey)' --template-body file://cf-template.yaml)

}


function create_change_set(){
        aws cloudformation create-change-set --stack-name sds-internal-change-sets --change-set-name $(cat changeset.name) --parameters file://parameters-dev.json --template-body file://cf-template.yaml

        if [[ $? -eq 255 ]]; then
                print_color 'red' 'PARAMETERS passed are incorrect, exiting the script'
                quit_execution

        fi

        aws cloudformation create-change-set --stack-name sds-internal-change-sets --change-set-name $(cat changeset.name) --parameters file://parameters-dev.json --template-body file://cf-template.yaml > create_change_set.txt

        cat > create_change_set_command.txt <<-EOF
        aws cloudformation create-change-set --stack-name sds-internal-change-sets --change-set-name $(cat changeset.name) --parameters file://parameters-dev.json --template-body file://cf-template.yaml
        EOF
}

function artifacts(){
        print_color 'green' '\n Logging the stack events to get_stack_events.txt'
        print_color 'green' '\n Logging the change set events to get_change_sets.txt'
        print_color 'green' '\n Logging the resources created by cloudformation to list_stack_resources.txt'
        print_color 'green' '\n Logging the output to output.txt'
        print_color 'green' '\n Logging the change set output.txt and command.txt'

        mkdir artifacts-$(date -d "today" +"%Y%m%d%H%M%S") && cp -r *.txt $_
        rm -rf *.txt

}

function print_color(){
  NC='\033[0m' 
  case $1 in

            "green") COLOR='\033[0;32m' 
                ;;
            "red") COLOR='\033[0;31m' 
                ;;
            "*") COLOR='\033[0m' 
                ;;
  esac
  echo -e "${COLOR} $2 ${NC}"

}

#Create Change set

echo -e '\n'
print_color 'green' 'Creating the Change Set'
create_change_set


#Check if Change set becomes available state in 30 secs

print_color 'green' '\n\nWaiting for change set to become available'

n=1
until [[ $n -ge 6 ]]; do

   check_changeset_available

   if [[ $check_available != "AVAILABLE" ]]; then
                print_color 'red' "\nChange set didn't become available in $n attempt"
   
                if [[ $n -eq 5 ]]; then
                        #statements
                        print_color 'red' "\n\nChange set didn't become available state within given time, exiting now"
                        quit_execution
                fi

   else
                print_color 'green' "\n\nChange set is now available after $n retries"
                break
   fi
   sleep 5s
  
   n=$((n+1)) 

done


#execute the change set

echo -e '\n'
print_color 'green' "\n\nExecute the change set. \nPlease wait while the resources are getting updated/created."

execute_change_set


#Show events

print_color 'green' "\n----Getting the deployment events----"
get_stack_events


#list the resources that are created

print_color 'green' "\n----List Stack resources----"
list_stack_resources


#show the output

print_color 'green' "\n----Display output----"
display_output


#save the artifacts for reference

print_color 'green' "\n----Copy the artifacts----"

artifacts
print_color 'green' "\n----You can find the artifacts in the same directory----"

#Complete
print_color 'green' "\n----Cloudformation template update was successfull!----"
