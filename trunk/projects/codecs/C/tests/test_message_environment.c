/* 
* Copyright (C) 2007, Brian Tanner

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

* 
*  $Revision$
*  $Date$
*  $Author$
*  $HeadURL$
* 
*/
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif


#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <rlglue/Environment_common.h>
#include <rlglue/utils/C/RLStruct_util.h>

#include "useful_functions.h"

char* responseMessage=0;
static observation_t* theObservation=0;

const char* env_init()
{    
	return "";
}

const observation_t *env_start()
{
	theObservation=allocateRLStructPointer(0,0,0);
	return theObservation;
}

const reward_observation_t *env_step(const action_t *a)
{
	static reward_observation_t ro={0};
	ro.observation=theObservation;
	return &ro;
}

void env_cleanup()
{
	if(responseMessage!=0){
		free(responseMessage);
		responseMessage=0;
	}
	freeRLStructPointer(theObservation);
	theObservation=0;
}

void env_set_state(const state_key_t *sk)
{
}
     
void env_set_random_seed(const random_seed_key_t *rsk)
{
}

const state_key_t *env_get_state()
{
	return 0;
}

const random_seed_key_t *env_get_random_seed()
{
	return 0;
}

const char* env_message(const char* inMessage) {
	char tmpBuffer[1024];
	
	if(inMessage==0)
		return "null";
	if(strcmp(inMessage,"")==0)
		return "empty";
	if(strcmp(inMessage,"null")==0)
		return 0;
	if(strcmp(inMessage,"empty")==0){
		return "";
		}
	sprintf(tmpBuffer,"%s", inMessage);

	if(responseMessage!=0){
		free(responseMessage);
		responseMessage=0;
	}
	responseMessage=(char *)calloc(strlen(tmpBuffer)+1,sizeof(char));
	sprintf(responseMessage,"%s",tmpBuffer);
	return responseMessage;
}
	
