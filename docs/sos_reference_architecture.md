# Referência de arquitetura — Sea of Stars (extraído de metadados IL2CPP)

> Apenas NOMES de namespaces/classes de código (estrutura), sem assets.
> Uso: aprender padrões do estúdio para aplicar no Pacto das Cinzas.

## Namespaces de gameplay (Sabotage.SeaOfStars.Script.* / Sabotage.Gameplay.*)

- `Sabotage.GameplayConditions`
- `Sabotage.GameplayConditions.Core.BasicConditions`
- `Sabotage.GameplayConditions.dll`
- `Sabotage.SeaOfStars.Script.AdditiveLevelLoader`
- `Sabotage.SeaOfStars.Script.Gameplay.AI`
- `Sabotage.SeaOfStars.Script.Gameplay.Fishing.Fishes`
- `Sabotage.SeaOfStars.Script.Graph.BehaviorTree.Nodes`
- `Sabotage.SeaOfStars.Script.Graph.BehaviorTree.Nodes.CharacterPatrolNode`
- `Sabotage.SeaOfStars.Script.Graph.BehaviorTree.Nodes.MoveCharacterNode`
- `Sabotage.SeaOfStars.Script.Graph.BehaviorTree.Nodes.RestoreFollowersStartFollowDistanceNode`
- `Sabotage.SeaOfStars.Script.Graph.BehaviorTree.Nodes.RestoreFollowersStopFollowDistanceNode`
- `Sabotage.SeaOfStars.Script.Graph.BehaviorTree.Nodes.SetFollowersStartFollowDistanceNode`
- `Sabotage.SeaOfStars.Script.Graph.BehaviorTree.Nodes.SetFollowersStopFollowDistanceNode`
- `Sabotage.SeaOfStars.Script.Graph.BehaviorTree.Nodes.SetLookDirectionNode`
- `Sabotage.SeaOfStars.Script.Graph.BehaviorTree.Nodes.WaitForFollowersNode`

## Padrões de arquitetura detectados

- **Behavior Tree (Sabotage.Graph.BehaviorTree)**: 23 símbolos
- **State Machine**: 39 símbolos
- **Timeline (cutscenes/sequências)**: 287 símbolos
- **Pooling**: 7 símbolos
- **Additive Level Loading (cenas contínuas)**: 36 símbolos
- **Parallax**: 4 símbolos
- **Ocean/água shader-based**: 23 símbolos
- **Pixel Perfect**: 35 símbolos
- **GameplayConditions (gating por estado de jogo)**: 4 símbolos
- **Cross-scene refs**: 13 símbolos
- **ScriptableObject com Id (data-driven)**: 2 símbolos
- **Localization própria**: 2 símbolos
- **Time of Day**: 8 símbolos
- **Verlet rope (cordas/efeitos físicos)**: 5 símbolos
- **Boids (cardumes)**: 34 símbolos

## Sistemas de gameplay (classes por palavra-chave)

### TimedHit
- `ActivateTimedHitUI`
- `AddTimedHitResult`
- `DoTeamTimedHitFeedback`
- `DoTimedHit`
- `DoTimedHitIndicatorFlash`
- `DoubleTimedHitOrBlock`
- `GetTimedHitBonusDamage`
- `GetTimedHitMultiplier`
- `MustShowTimedHitUI`
- `OnTimedHitResult`
- `PoisonBladeTimedHit`
- `TimedHitDamageFeedback`
### Timing
- `GatherBstTimings`
- `GatherGarlTimings`
- `GatherSunboyTimings`
- `GatherTimings`
- `GetFrameTiming`
- `LogTiming`
- `ResetFrameTiming`
- `TTimingData`
- `TimingData`
- `Timings2`
- `TransitionTimingFunction`
### LiveMana
- `AbsorbLiveMana`
- `AbstractLiveManaSpawnQuantityModifier`
- `ActivateLiveMana`
- `ActivateLiveManaCoroutine`
- `AddBigLiveManaParticle`
- `BigLiveMana`
- `BigLiveManaAbsorbState`
- `BigLiveManaDestroyState`
- `BigLiveManaIdleState`
- `BigLiveManaMergeState`
- `BigLiveManaParticle`
- `BigLiveManaParticles`
### Combo
- `AddComboPoints`
- `ApplyComboPointsMultiplier`
- `AwardComboMoveMana`
- `AwardComboPointGameAction`
- `AwardComboPointReward`
- `AwardedComboPointsModifier`
- `COMBOPOINT`
- `COMBO_POINTS_INCREASE_PERCENTAGE`
- `COMBO_POINT_FILL_AMOUNT`
- `CanUseComboPoints`
- `CircusLevelUpComboScreen`
- `ComboBattleCommand`
### Lock
- `ACTION_LOCK_WHEEL`
- `ACTION_UNLOCK_WHEEL`
- `ASSEMBLY_LOOKUP_LOCK`
- `ASSEMBLY_REGISTER_QUEUE_LOCK`
- `AUTHORITYLOCKLODLOD`
- `AbstractLockCastingCombatMoveParams`
- `AccountLockedDown`
- `AcquireAllLocks`
- `AcquireLocks`
- `AcquireWriterLock`
- `ActivateScenesToUnblockPartySwap`
- `AddActionTimerLock`
### Relic
- `ANIM_FROM_RELIC`
- `ANIM_TO_RELIC`
- `ApplyRelicSelection`
- `ArtfulGambit_Relic`
- `ClearRelicScrollList`
- `ClearRelics`
- `DisableAllRelics`
- `DisableRelic`
- `DoUnlockAllRelics`
- `EnableRelic`
- `FillRelicScrollList`
- `GameMenuRelicButton`
### Cooking
- `CAMP_COOKING`
- `COOKINGACTION`
- `CookingAction`
- `CookingActionDurationModifier`
- `CookingActionInfo`
- `CookingActionSection`
- `CookingInteractiveObject`
- `CookingManager`
- `CookingScreen`
- `CookingScreenButton`
- `CookingScreenMessage`
- `CookingScreenParams`
### Campfire
- `CampfireInteraction`
- `PLAY_CAMPFIRE`
- `PLAY_GPI_SCIFICAMPFIRE`
- `STOP_CAMPFIRE`
- `STOP_GPI_SCIFICAMPFIRE`
- `STOP_GPI_SCIFICAMPFIRE_ON`
### Fishing
- `AddFishingLineHPModifier`
- `AddFishingLineRegenSpeed`
- `AddFishingPoleReelingSpeedModifier`
- `AddFishingSidePullStrengthModifier`
- `BeginFishing`
- `BeginFishingCamera`
- `CancelFishing`
- `EFishingCastSteps`
- `EndFishing`
- `EndFishingCamera`
- `ExitFishingCoroutine`
- `FISHING_PREVIEW_RENDERER`
### WorldMap
- `ActivateWorldMapCamping`
- `BatchWorldMapSections`
- `BrownWorkUnitWorldMapLevelInitializer`
- `CanEnterWorldMapCamping`
- `DLC_TOTW_WORLDMAP`
- `DefaultWorldMapCampingSequence`
- `DoUnloadStreamingWorldMap`
- `DoUnloadStreamingWorldMap_OnMapSectionUnloaded`
- `GetClosestWorldMapCampingSpot`
- `GetWorldMapFlyDown`
- `GetWorldMapSectionLoadingZone`
- `InitializeStreamingWorldMap`
### Teleporter
- `ChangeInLevelTeleporterPositionNode`
- `CryptTeleporter`
- `CurrentTeleporter`
- `ExecuteTeleporterNode`
- `GetHighlightedTeleporter`
- `HandleTeleporterEntrance`
- `HighlightCryptTeleporterNode`
- `HighlightTeleporter`
- `InInLevelTeleporter`
- `InLevelTeleporter`
- `InitializeTeleporters`
- `IsCharacterInTeleporterTrigger`
### Cutscene
- `AbstractCutsceneDecoratorNode`
- `AssignCutsceneTriggerer`
- `AttemptTriggerCutscene`
- `BeginCutsceneTransition`
- `BoatCutsceneDecoratorNode`
- `CantGiveLootDialogCutscene_OnDone`
- `Cheat0AdditionalPlayerCutscene`
- `ClearCutsceneBars`
- `CloseCutsceneBars`
- `CombatCutsceneDecorator`
- `CutCutsceneType`
- `Cutscene`
### Quest
- `AbortRequested`
- `AddRequest`
- `AllowHttpRequestHeader`
- `AreAllQuestionPacksCleared`
- `AskNextQuestion`
- `AssetBundleCreateRequest`
- `AssetBundleRequest`
- `AssetBundleRequestOptions`
- `AsyncCoroutineRunnerAsyncRequestCallbackAsynchronous`
- `AsyncHandshakeRequest`
- `AsyncProtocolRequest`
- `AsyncReadManagerRequestMetric`
### Dialog
- `AfterDialogEvent`
- `BeforeDialogEvent`
- `CSharp_GetDialogueEventCustomPropertyValue__SWIG_0`
- `CSharp_GetDialogueEventCustomPropertyValue__SWIG_1`
- `CSharp_ResolveDialogueEvent__SWIG_0`
- `CSharp_ResolveDialogueEvent__SWIG_1`
- `CancelDialog`
- `CantGiveLootDialogCutscene_OnDone`
- `CloseAllRegisteredDialogs`
- `CloseDialog`
- `CloseDialogBox`
- `CloseDialogNode`
### Party
- `AbstractLeavePartyInventory`
- `ActivateScenesToUnblockPartySwap`
- `AddCharacterToCombatParty`
- `AddGuestPartyMemberNode`
- `AddLoadedParty`
- `AddPartyMember`
- `AddPartyMemberNode`
- `AddToCombatParty`
- `AkPartyLeaderTriggerEnter`
- `AkPartyLeaderTriggerExit`
- `ApplyRenderingSettingsToParty`
- `AssetReferenceGameObjectByEPartyCharacterVariant`
### Skill
- `AbsoluteSkillMPCostModifier`
- `BattleCommandSelectorSkillsItem`
- `BoulderGoatChargeSkill`
- `CheckTOTWAllSkillsAchievement`
- `DisableAllBattleCommandsExceptSkills`
- `DisableAllSkillsExceptSunballAndMoonrang`
- `EnableAllSkills`
- `EnemySkillCombatMove`
- `EnterSkillSection`
- `FullHealPartySkillPoints`
- `GameMenuCharacterSectionSkillInfo`
- `GameMenuCharacterSectionSkillInfoLabel`
### Spell
- `AbsolutePlayerSpellPowerModifier`
- `AllSpellsDoneHitting`
- `BDimSunlightForSpellCastGameAction`
- `BreakSpellLocks`
- `BubbleSpell`
- `CanPlayerCastSpellWithDamageType`
- `CastSpell`
- `CastSpellInstance`
- `CastSpellInstances`
- `CastSpellInstancesCoroutine`
- `CogRainSpell`
- `CombatAnimatedSpell`
### Shake
- `AfterShakeParams`
- `AsyncHandshakeRequest`
- `BeforeShakeParams`
- `BeginShake`
- `CameraPerlinShakeAdditiveContext`
- `CameraShake`
- `CameraShakeAdditiveContext`
- `CameraShakeSettings`
- `CameraShakeTimelineBehaviour`
- `CameraShakeTimelineClip`
- `CameraShakeTimelineTrack`
- `CameraShakeTimelineTrackMixer`
### Boost
- `BOOSTLEVEL`
- `BeginBoostCountDownForAll`
- `BeginSpeedBoostCountdown`
- `BeginTeleportBoostFX`
- `BoatBoost`
- `BoatBoost3DCameraContext`
- `BoatBoost3DCameraContextParam`
- `BoatSoSBoostState`
- `BoomerAngstInBoostLevelBopBoston`
- `BoostEndTime`
- `BoostFXInstance`
- `BoostLeft`
### Dungeon
- `CatchDungeon`
- `DLC_TOTW_CURSEDBIGTOPDUNGEON`
- `DLC_TOTW_LIGHTFORTRESSDUNGEON`
- `DLC_TOTW_PRISONDUNGEON`
- `DLC_TOTW_TRAINDRIVERDUNGEON`
- `DLC_TOTW_WOLFMOUNTAINDUNGEON`
- `FishingDungeon`
- `FishingDungeonBiteState`
- `FishingDungeonHookedBehaviour`
- `FishingLurePullDungeonState`
- `FishingMinigameCatchDungeonState`
- `PLAY_AMBIENCE_PRISONDUNGEON`
### Encounter
- `AbstractEncounterPlayerSlotAssignator`
- `AbstractEnemyEncounterIntroBehaviour`
- `AddRunningEncounter`
- `AllEnemiesDeadEncounterEndCondition`
- `AllowFollowerEnterEncounter`
- `AttemptDisableEncountersOnInteract`
- `AttemptEnableEncountersAfterInteract`
- `BeginEncounter`
- `BeginReturnToEncounter`
- `BehaviourTreeEncounterIntro`
- `BehaviourTreeEncounterOutro`
- `BlockEncounter`


## Save format (SOS_Options/SaveSlot*.sos) — decodificado 2026-09-07

Formato: uint16 LE (magic/version) + JSON UTF-8 puro (legível, versionado por saveVersion int).

Top keys do SaveSlot (o que um JRPG SoS persiste):
- **Identidade**: saveId (guid), slotIndex, saveVersion, saveIterations (contador de saves), timestamp, deathCount
- **Progresso macro**: partyProgressData/circusProgressData = {totalXP, currentLevel, unspentXP} (XP é do PARTY, não por char)
- **Posição**: checkpointData = {savepointId, position xyz, levelDefinitionGuid, playerOrientation (int!), isBoat}
- **characterData**: dict por CharacterId (ZALE/VALERE/SERAI/...): currentHP/currentSP/currentClassType/equips por itemGuid (weapon/armor/2 trinkets + group trinket + leavePartyInventory quando sai da party)
- **progressionSaveData**: playTime, saveCount, openedChests[], defeatedPermaDeathEnemies[], locksRevealedByEnemyByMove (analise Kaelen!), unlockedCombatMoves[]
- **blackboardDictionary**: chave-valor genérico para flags de mundo (o nosso world_state)
- **Sistemas separados**: gpiStateSaveDatas (gameplay objects), gathering, loot, boat, achievements, codex, inventory, currency, relics, quiz, pirateMusic

Lições aplicáveis ao Pacto:
1. XP/level é da PARTY (simplifica nosso progression_system)
2. Flags de mundo = blackboard genérico (nosso game_data.game_data vira isso)
3. Sets de 'coisas vistas': arrays de IDs (chests, inimigos perma-death, locks revelados) — igualzinho ao nosso opened_chests
4. Equips referenciam itemGuid, nunca stats copiados — recalcula ao carregar
5. playerOrientation como int de 8 direções (não float)
6. saveIterations/saveCount para detectar save corrompido (nunca sobrescrever iter-1)


## Audio: 377 bancos Wwise — organização por LOCAL (não por sistema)

Padrão de nomes: SB<n>_<Região>_<Subárea> (SB1_EvermistIsland_ForbiddenCavern),
DLC_TOTW_<...>, + Globais (Init, SFX_Common, Archivist).
Bancos por região carregam música/ambience juntos; SFX comum separado.

Aplicável: nosso SoundManager procedural pode adotar mesma organização:
1 bank por mapa (música+ambience) + 1 SFX_Common global + gameplay banks (arena).

## Insights acionáveis para o Pacto das Cinzas (resumo executivo)

1. **Behavior Tree para NPCs/IA** — SoS usa BT como espinha dorsal (patrulha,
   seguir followers, look direction, cutscene triggers). Nosso enemy_ai.gd é
   if-chain; evoluir para árvore de nós simples (idem Kaelen).
2. **Timeline como motor de cutscenes** (287 símbolos!) — cutscenes são dados,
   não código. Nossa act_cutscene é hard-coded: virar lista de ações.
3. **AdditiveLevelLoader + StreamingWorldMap** — cenas contínuas carregadas
   aditivamente por seção. Nossa troca de mapa já é in-place: alinhar
   LoadWorldMapSection/Unload com o nosso map_id (mesma arquitetura).
4. **GameplayConditions** — gating por estado de jogo como sistema próprio
   (condições avaliáveis, não ifs espalhados). Nosso campaign_system + world_state
   podem expor um evaluate(condition) único.
5. **LiveMana com máquina de estados por partícula** (Idle/Absorb/Merge/Destroy)
   — nosso ether_system visual pode usar o mesmo padrão de estados.
6. **TimedHit como pipeline** (Activate UI → Indicator flash → Result →
   Damage feedback → Bonus damage → Double or block) — espelha nosso
   timed_combat_system; confirmar todos os estágios existem.
7. **CameraShake com Timeline track** — shake é settings + additive context;
   nosso screen_effects.shake pode aceitar params struct.
8. **Save**: ver seção do formato acima (blackboard, party XP, itemGuid).
