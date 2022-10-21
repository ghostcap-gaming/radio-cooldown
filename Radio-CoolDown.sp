#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required
#pragma semicolon 1

#define PREFIX " \x04[Radio-Spam]\x01"

enum struct CoolDown
{
	bool active;
	int cooldown_finish;
	
	int first_message_time;
	int num_of_messages;
	
	void Reset()
	{
		this.active = false;
		this.cooldown_finish = 0;
		this.first_message_time = 0;
		this.num_of_messages = 0;
	}
}
CoolDown g_CoolDowns[MAXPLAYERS + 1];

ConVar g_CheckDuration;
ConVar g_SpamThreshold;
ConVar g_CooldownDuration;

public Plugin myinfo = 
{
	name = "Radio Anti-Flood", 
	author = "LuqS", 
	description = "Bye Radio Spammers", 
	version = "1.0", 
	url = "https://steamcommunity.com/id/LuqSGood"
};

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO only.");
	}
	
	// My super duper optimal settings
	g_CheckDuration = CreateConVar("radio_cooldown_check_duration", "3", "The amount of time in seconds to put player under spam check, to see if he passes the spam threshold", _, true, 2.0);
	g_SpamThreshold = CreateConVar("radio_cooldown_spam_threshold", "3", "Amount of messages to count as spam, in the given time (radio_cooldown_check_duration)", _, true, 2.0);
	g_CooldownDuration = CreateConVar("radio_cooldown_duration", "10", "The Amount of seconds the player will be in cooldown after reaching spamming limit", _, true, 1.0);
	
	AutoExecConfig();
	
	//Radio Menu 1
	AddCommandListener(Command_SentRadioMessage, "go");
	AddCommandListener(Command_SentRadioMessage, "fallback");
	AddCommandListener(Command_SentRadioMessage, "sticktog");
	AddCommandListener(Command_SentRadioMessage, "holdpos");
	AddCommandListener(Command_SentRadioMessage, "followme");
	//Radio Menu 2
	AddCommandListener(Command_SentRadioMessage, "roger");
	AddCommandListener(Command_SentRadioMessage, "negative");
	AddCommandListener(Command_SentRadioMessage, "cheer");
	AddCommandListener(Command_SentRadioMessage, "compliment");
	AddCommandListener(Command_SentRadioMessage, "thanks");
	//Radio Menu 3
	AddCommandListener(Command_SentRadioMessage, "enemyspot");
	AddCommandListener(Command_SentRadioMessage, "needbackup");
	AddCommandListener(Command_SentRadioMessage, "takepoint");
	AddCommandListener(Command_SentRadioMessage, "sectorclear");
	AddCommandListener(Command_SentRadioMessage, "inposition");
	
	//Radio Commands That Can Be Used With Console
	AddCommandListener(Command_SentRadioMessage, "coverme");
	AddCommandListener(Command_SentRadioMessage, "regroup");
	AddCommandListener(Command_SentRadioMessage, "takingfire");
	AddCommandListener(Command_SentRadioMessage, "stormfront");
	AddCommandListener(Command_SentRadioMessage, "report");
	AddCommandListener(Command_SentRadioMessage, "getout");
	AddCommandListener(Command_SentRadioMessage, "enemydown");
	AddCommandListener(Command_SentRadioMessage, "getinpos");
	AddCommandListener(Command_SentRadioMessage, "reportingin");
}

public Action Command_SentRadioMessage(int client, const char[] Command, int args)
{	
	// Lets not call this function 1000 times
	int current_time = GetTime();
	
	// Player on cooldown?
	if (g_CoolDowns[client].active)
	{
		// You need to wait
		if (current_time < g_CoolDowns[client].cooldown_finish)
		{
			PrintToChat(client, "%s Your radio privileges will be restored in %d seconds.", PREFIX, g_CoolDowns[client].cooldown_finish - current_time);
			return Plugin_Stop;
		}
		
		// Don't be a bad boy again!
		g_CoolDowns[client].Reset();
	}
	
	// Be careful when you send those....
	g_CoolDowns[client].num_of_messages++;
	
	// First message.
	if (g_CoolDowns[client].num_of_messages == 1)
	{
		// Save the first message time.
		g_CoolDowns[client].first_message_time = current_time;
	}
	// It wasn't the first or last message, now check if he is a good boy.
	else if (current_time - g_CoolDowns[client].first_message_time > g_CheckDuration.IntValue)
	{
		g_CoolDowns[client].Reset();
	}
	// Reached spam threshold.
	else if (g_CoolDowns[client].num_of_messages == g_SpamThreshold.IntValue)
	{
		// Bad boy.
		g_CoolDowns[client].active = true;
		
		// Calculate when the cooldown should finish.
		g_CoolDowns[client].cooldown_finish = current_time + g_CooldownDuration.IntValue;
		
		// Alert the player he is brain dead.
		PrintToChat(client, "%s \x02Your radio privileges have been suspended due to spam!", PREFIX);
		PrintToChat(client, "%s You will regain the ability to use the radio in \x04%d\x01 seconds.", PREFIX, g_CooldownDuration.IntValue);
		
		// Don't send the radio message.
		return Plugin_Stop;
	}
	
	// All good!
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	// Bye Bye data
	g_CoolDowns[client].Reset();
} 