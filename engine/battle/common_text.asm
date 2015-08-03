PrintBeginningBattleText: ; f4000 (3d:4000)
	ld a, [W_ISINBATTLE] ; W_ISINBATTLE
	dec a
	jr nz, .trainerBattle
	ld a, [W_CURMAP] ; W_CURMAP
	cp POKEMONTOWER_3
	jr c, .notPokemonTower
	cp LAVENDER_HOUSE_1
	jr c, .pokemonTower
.notPokemonTower
	ld a,[W_BATTLETYPE]
	cp $4 ; new battle type?
	jr nz,.notnewbattletype
	callab Func_fd0d0
	ld e,$24
	jr c,.asm_f4026
	ld e,$a
.asm_f4026
	callab Func_f0000
	jr .continue
.notnewbattletype
	ld a, [wEnemyMonSpecies2]
	call PlayCry
.continue
	ld hl, WildMonAppearedText
	ld a, [W_MOVEMISSED] ; W_MOVEMISSED
	and a
	jr z, .notFishing
	ld hl, HookedMonAttackedText
.notFishing
	jr .wildBattle
.trainerBattle
	call .playSFX
	ld c, $14
	call DelayFrames
	ld hl, TrainerWantsToFightText
.wildBattle
	push hl
	callab DrawAllPokeballs
	pop hl
	call PrintText
	jr .done
.pokemonTower
	ld b, SILPH_SCOPE
	call IsItemInBag
	ld a, [wEnemyMonSpecies2]
	ld [wcf91], a
	cp MAROWAK
	jr z, .isMarowak
	ld a, b
	and a
	jr z, .noSilphScope
	callab LoadEnemyMonData
	jr .notPokemonTower
.noSilphScope
	ld hl, EnemyAppearedText
	call PrintText
	ld hl, GhostCantBeIDdText
	call PrintText
	jr .done
.isMarowak
	ld a, b
	and a
	jr z, .noSilphScope
	ld hl, EnemyAppearedText
	call PrintText
	ld hl, UnveiledGhostText
	call PrintText
	callab LoadEnemyMonData
	callab MarowakAnim
	ld hl, WildMonAppearedText
	call PrintText

.playSFX
	xor a
	ld [wc0f1], a
	ld a, $80
	ld [wc0f2], a
	ld a, $e9 ; (SFX_08_77 - SFX_Headers_08) / 3
	call PlaySound
	jp WaitForSoundToFinish
.done
	ret

WildMonAppearedText: ; f40c7 (3d:40c7)
	TX_FAR _WildMonAppearedText
	db "@"

HookedMonAttackedText: ; f40cc (3d:40cc)
	TX_FAR _HookedMonAttackedText
	db "@"

EnemyAppearedText: ; f40d1 (3d:40d1)
	TX_FAR _EnemyAppearedText
	db "@"

TrainerWantsToFightText: ; f40d6 (3d:40d6)
	TX_FAR _TrainerWantsToFightText
	db "@"

UnveiledGhostText: ; f40db (3d:40db)
	TX_FAR _UnveiledGhostText
	db "@"

GhostCantBeIDdText: ; f40e0 (3d:40e0)
	TX_FAR _GhostCantBeIDdText
	db "@"

PrintSendOutMonMessage: ; f40e0 (3d:40e5)
	ld hl, wEnemyMonHP
	ld a, [hli]
	or [hl]
	ld hl, GoText
	jr z, .printText
	xor a
	ld [H_MULTIPLICAND], a
	ld hl, wEnemyMonHP
	ld a, [hli]
	ld [wcce3], a
	ld [H_MULTIPLICAND + 1], a
	ld a, [hl]
	ld [wcce4], a
	ld [H_MULTIPLICAND + 2], a
	ld a, 25
	ld [H_MULTIPLIER], a
	call Multiply
	ld hl, wEnemyMonMaxHP
	ld a, [hli]
	ld b, [hl]
	srl a
	rr b
	srl a
	rr b
	ld a, b
	ld b, $4
	ld [H_DIVISOR], a ; enemy mon max HP divided by 4
	call Divide
	ld a, [H_QUOTIENT + 3] ; a = (enemy mon current HP * 25) / (enemy max HP / 4); this approximates the current percentage of max HP
	ld hl, GoText ; 70% or greater
	cp 70
	jr nc, .printText	
	ld hl, DoItText ; 40% - 69%
	cp 40
	jr nc, .printText
	ld hl, GetmText ; 10% - 39%
	cp 10
	jr nc, .printText
	ld hl, EnemysWeakText ; 0% - 9%
.printText
	jp PrintText

GoText: ; f413a (3d:413a)
	TX_FAR _GoText
	db $08 ; asm
	jr PrintPlayerMon1Text

DoItText: ; f4141 (3d:4141)
	TX_FAR _DoItText
	db $08 ; asm
	jr PrintPlayerMon1Text

GetmText: ; f4148 (3d:4148)
	TX_FAR _GetmText
	db $08 ; asm
	jr PrintPlayerMon1Text

EnemysWeakText: ; f414f (3d:414f)
	TX_FAR _EnemysWeakText
	db $08 ; asm

PrintPlayerMon1Text: ; f4154 (3d:4154)
	ld hl, PlayerMon1Text
	ret

PlayerMon1Text: ; f4158 (3d:4158)
	TX_FAR _PlayerMon1Text
	db "@"

RetreatMon: ; f415d (3d:415d)
	ld hl, PlayerMon2Text
	jp PrintText

PlayerMon2Text: ; f4163 (3d:4163)
	TX_FAR _PlayerMon2Text
	db $08 ; asm
	push de
	push bc
	ld hl, wEnemyMonHP + 1
	ld de, wcce4
	ld b, [hl]
	dec hl
	ld a, [de]
	sub b
	ld [$ff98], a
	dec de
	ld b, [hl]
	ld a, [de]
	sbc b
	ld [$ff97], a
	ld a, $19
	ld [H_POWEROFTEN], a
	call Multiply
	ld hl, wEnemyMonMaxHP
	ld a, [hli]
	ld b, [hl]
	srl a
	rr b
	srl a
	rr b
	ld a, b
	ld b, $4
	ld [H_POWEROFTEN], a
	call Divide
	pop bc
	pop de
	ld a, [$ff98]
	ld hl, EnoughText
	and a
	ret z
	ld hl, ComeBackText
	cp $1e
	ret c
	ld hl, OKExclamationText
	cp $46
	ret c
	ld hl, GoodText
	ret

EnoughText: ; f41b1 (3d:41b1)
	TX_FAR _EnoughText
	db $08 ; asm
	jr PrintComeBackText

OKExclamationText: ; f41b8 (3d:41b8)
	TX_FAR _OKExclamationText
	db $08 ; asm
	jr PrintComeBackText

GoodText: ; f41bf (3d:41bf)
	TX_FAR _GoodText
	db $08 ; asm
	jr PrintComeBackText

PrintComeBackText: ; f41c6 (3d:41c6)
	ld hl, ComeBackText
	ret

ComeBackText: ; f41ca (3d:41ca)
	TX_FAR _ComeBackText
	db "@"
