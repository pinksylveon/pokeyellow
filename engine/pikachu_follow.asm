ShouldPikachuSpawn:: ; fc4dd (3f:44dd)
; possibly to test if pika should be out?
	ld a, [wPikachuOverworldStateFlags]
	bit 5, a
	jr nz, .hide ; 3f:44f8
	ld a, [wPikachuOverworldStateFlags]
	bit 7, a
	jr nz, .hide
	call IsStarterPikachuInOurParty
	jr nc, .hide
	ld a, [wWalkBikeSurfState]
	and a
	jr nz, .hide
	scf
	ret

.hide
	and a
	ret

SchedulePikachuSpawnForAfterText:: ; fc4fa (3f:44fa)
	ld hl, wPikachuOverworldStateFlags
	bit 4, [hl]
	res 4, [hl]
	jr nz, .normal_spawn_state
	call EnablePikachuFollowingPlayer
	call ClearPikachuSpriteStateData
	ld a, $ff
	ld [wPikachuSpriteImageIdx], a
	call ClearPikachuFollowCommandBuffer
	call CalculatePikachuFacingDirection
	ret

.normal_spawn_state
	call CalculatePikachuPlacementCoords
	xor a
	ld [wPikachuSpawnState], a
	ld a, [wPlayerFacingDirection]
	ld [wPikachuFacingDirection], a
	ret

ClearPikachuSpriteStateData:: ; fc523 (3f:4523)
	ld hl, wPikachuPictureID
	call .clear
	ld hl, wPikachuSpriteStateData2
.clear
	ld bc, $10
	xor a
	call FillMemory
	ret

CalculatePikachuSpawnCoordsAndFacing:: ; fc534 (3f:4534)
	call CalculatePikachuPlacementCoords
	call CalculatePikachuFacingDirection
	xor a
	ld [wPikachuSpawnState], a
	ret

CalculatePikachuPlacementCoords:: ; fc53f (3f:453f)
	ld bc, wPikachuPictureID
	ld a, [wYCoord]
	add $4
	ld e, a
	ld a, [wXCoord]
	add $4
	ld d, a
	ld a, [wPikachuSpawnState]
	and a
	jr z, .load_coords
	cp $1
	jr z, .right_of_player
	cp $2
	jr z, .check_player_facing2
	cp $3
	jr z, .load_coords
	cp $4
	jr z, .below_player
	cp $5
	jr z, .above_player
	cp $6
	jr z, .left_of_player
	cp $7
	jr z, .check_player_facing
	jr .right_of_player

.check_player_facing
	ld a, [wPlayerFacingDirection]
	and a ; SPRITE_FACING_DOWN
	jr z, .below_player
	cp SPRITE_FACING_UP
	jr z, .above_player
	cp SPRITE_FACING_LEFT
	jr z, .left_of_player
	cp SPRITE_FACING_RIGHT
	jr z, .right_of_player
.check_player_facing2
	ld a, [wPlayerFacingDirection]
	and a
	jr nz, .check_up
	dec e
	jr .load_coords

.check_up
	cp SPRITE_FACING_UP
	jr nz, .check_left
	inc e
	jr .load_coords

.check_left
	cp SPRITE_FACING_LEFT
	jr nz, .left_of_player_2
	inc d
	jr .load_coords

.left_of_player_2
	dec d
	jr .load_coords

.right_of_player
	inc d
	jr .load_coords

.left_of_player
	dec d
	jr .load_coords

.below_player
	inc e
	jr .load_coords

.above_player
	dec e
	jr .load_coords ; useless jr
.load_coords
	ld hl, wPlayerMapY - wPlayerSpriteStateData1
	add hl, bc
	ld [hl], e
	inc hl
	ld [hl], d
	inc hl
	ld [hl], $fe
	push hl
	ld hl, wd472
	set 5, [hl]
	pop hl
	ret

CalculatePikachuFacingDirection:: ; fc5bc (3f:45bc)
	ld a, $49
	ld [wPikachuPictureID], a
	ld a, $ff
	ld [wPikachuSpriteImageIdx], a
	ld a, [wPikachuSpawnState]
	and a
	jr z, .copy_player_facing
	cp $1
	jr z, .copy_player_facing
	cp $3
	jr z, .force_facing_down
	cp $4
	jr z, .copy_player_facing
	cp $6
	jr z, .copy_player_facing
	cp $7
	jr z, .face_the_other_way
	call ComputePikachuFacingDirection
	ret

.copy_player_facing
	ld a, [wPlayerFacingDirection]
	ld [wPikachuFacingDirection], a
	ret

.force_facing_down
	ld a, SPRITE_FACING_DOWN
	ld [wPikachuFacingDirection], a
	ret

.face_the_other_way
	ld a, [wPlayerFacingDirection]
	xor $4
	ld [wPikachuFacingDirection], a
	ret

CalculatePikachuSpawnState1:: ; fc5fa (3f:45fa)
	ld a, [wCurMap]
	cp OAKS_LAB
	jr z, .oaks_lab
	cp ROUTE_22_GATE
	jr z, .route_22_gate
	cp MT_MOON_2
	jr z, .mt_moon_2
	cp ROCK_TUNNEL_1
	jr z, .rock_tunnel_1
	ld a, [wCurMap]
	ld hl, Pointer_fc64b
	call Pikachu_IsInArray ; similar to IsInArray, but not the same
	jr c, .map_list_1
	ld a, [wCurMap]
	ld hl, Pointer_fc653
	call Pikachu_IsInArray
	jr nc, .not_map_list_2
	ld a, [wPlayerFacingDirection]
	and a
	jr nz, .not_map_list_2
	ld a, $3
	jr .load

.route_22_gate
	ld a, [wPlayerFacingDirection]
	and a
	jr z, .rock_tunnel_1
	jr .not_map_list_2

.mt_moon_2
	ld a, $3
	jr .load

.map_list_1
	ld a, $4
	jr .load

.oaks_lab
	ld a, $6
	jr .load

.not_map_list_2
	ld a, $1
	jr .load

.rock_tunnel_1
	ld a, $3
.load
	ld [wPikachuSpawnState], a
	ret

Pointer_fc64b:: ; fc64b (3f:464b)
	db VICTORY_ROAD_2
	db ROUTE_7_GATE
	db ROUTE_8_GATE
	db ROUTE_16_GATE_1F
	db ROUTE_18_GATE_1F
	db ROUTE_15_GATE_1F
	db ROUTE_11_GATE_1F
	db $ff

Pointer_fc653:: ; fc653 (3f:4653)
	db VIRIDIAN_FOREST_EXIT
	db CERULEAN_HOUSE_2
	db TRASHED_HOUSE
	db VERMILION_DOCK
	db CELADON_MANSION_1
	db ROUTE_2_GATE
	db FUCHSIA_HOUSE_3
	db $ff

CalculatePikachuSpawnState2:: ; fc65b (3f:465b)
	ld a, [wCurMap]
	cp VIRIDIAN_FOREST_EXIT
	jr z, .viridian_forest_exit
	cp VIRIDIAN_FOREST_ENTRANCE
	jr z, .viridian_forest_entrance
	ld a, [wCurMap]
	ld hl, Pointer_fc68e
	call Pikachu_IsInArray
	jr c, .in_array
	jr .not_in_array

.viridian_forest_exit
	ld a, [wPlayerFacingDirection]
	cp SPRITE_FACING_UP
	jr z, .in_array
	jr .not_in_array

.viridian_forest_entrance
	ld a, [wPlayerFacingDirection]
	and a ; SPRITE_FACING_DOWN
	jr z, .not_in_array
	jr .in_array

.not_in_array
	ld a, $0
	jr .load_spawn_state

.in_array
	ld a, $1
.load_spawn_state
	ld [wPikachuSpawnState], a
	ret

Pointer_fc68e:: ; fc68e (3f:468e)
	db VIRIDIAN_FOREST
	db SAFARI_ZONE_REST_HOUSE_1
	db SAFARI_ZONE_REST_HOUSE_2
	db SAFARI_ZONE_REST_HOUSE_3
	db SAFARI_ZONE_REST_HOUSE_4
	db SAFARI_ZONE_SECRET_HOUSE
	db SILPH_CO_ELEVATOR
	db CELADON_MART_ELEVATOR
	db CINNABAR_LAB_2
	db CINNABAR_LAB_3
	db CINNABAR_LAB_4
	db $ff

CalculatePikachuSpawnState3:: ; fc69a (3f:469a)
	ld a, [wCurMap]
	cp ROUTE_22_GATE
	jr z, .asm_fc6a7
	cp ROUTE_2_GATE
	jr z, .asm_fc6b0
	jr .asm_fc6bd

.asm_fc6a7
	ld a, [wPlayerFacingDirection]
	cp SPRITE_FACING_UP
	jr z, .asm_fc6b9
	jr .asm_fc6bd

.asm_fc6b0
	ld a, [wPlayerFacingDirection]
	cp SPRITE_FACING_UP
	jr z, .asm_fc6b9
	jr .asm_fc6bd

.asm_fc6b9
	ld a, $1
	jr .asm_fc6c1

.asm_fc6bd
	ld a, $3
	jr .asm_fc6c1

.asm_fc6c1
	ld [wPikachuSpawnState], a
	ret

SetPikachuOverworldStateFlag2:: ; fc6c5 (3f:46c5)
	push hl
	ld hl, wPikachuOverworldStateFlags
	set 2, [hl]
	pop hl
	ret

ResetPikachuOverworldStateFlag2:: ; fc6cd (3f:46cd)
	push hl
	ld hl, wPikachuOverworldStateFlags
	res 2, [hl]
	pop hl
	ret

SpawnPikachu_:: ; fc6d5 (3f:46d5)
	call ResetPikachuOverworldStateFlag2
	call TrySpawnPikachu
	ret nc

	push bc
	call WillPikachuSpawnOnTheScreen
	pop bc
	ret c

	ld bc, wPikachuSpriteStateData1
	ld hl, wPikachuMovementStatus - wPikachuSpriteStateData1
	add hl, bc
	bit 7, [hl]
	jp nz, Func_fc745
	ld a, [wFontLoaded]
	bit 0, a
	jp nz, Func_fc76a
	call CheckPikachuFollowingPlayer
	jp nz, Func_fc76a
	ld a, [hl]
	and $7f
	cp $a
	jr c, .valid
	xor a
.valid
	add a
	ld e, a
	ld d, 0
	ld hl, PointerTable_fc710
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp hl

PointerTable_fc710: ; fc710 (3f:4710)
	dw Func_fc793
	dw Func_fc7aa
	dw Func_fc803
	dw asm_fc9c3
	dw asm_fca1c
	dw asm_fc9ee
	dw asm_fc87f
	dw asm_fc904
	dw asm_fc937
	dw asm_fc969
	dw .nop

.nop: ; fc726 (3f:4726)
	ret

TrySpawnPikachu: ; fc727 (3f:4727)
	call ShouldPikachuSpawn
	jr nc, .dont_spawn
	ld a, [wPikachuMovementStatus]
	and a
	jr nz, .already_spawned
	push bc
	push hl
	call CalculatePikachuSpawnCoordsAndFacing
	pop hl
	pop bc
.already_spawned
	scf
	ret

.dont_spawn
	ld hl, wPikachuSpriteImageIdx
	ld [hl], $ff
	dec hl
	ld [hl], $0
	xor a
	ret

Func_fc745: ; fc745 (3f:4745)
	ld hl, wPikachuMovementStatus - wPikachuSpriteStateData1
	add hl, bc
	res 7, [hl]
	ld hl, wPikachuWalkAnimationCounter - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], a
	call CheckPikachuFollowingPlayer
	jr nz, .asm_fc75f
	ld a, [wPlayerFacingDirection]
	xor $4
	ld hl, wPikachuFacingDirection - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], a
.asm_fc75f
	xor a
	ld hl, wPikachuIntraAnimFrameCounter - wPikachuSpriteStateData1
	add hl, bc
	ld [hli], a
	ld [hl], a
	call UpdatePikachuWalkingSprite
	ret

Func_fc76a: ; fc76a (3f:476a)
	xor a
	ld hl, wPikachuIntraAnimFrameCounter - wPikachuSpriteStateData1
	add hl, bc
	ld [hli], a
	ld [hl], a
	call UpdatePikachuWalkingSprite
	call Func_fc82e
	jr c, .asm_fc783
	push bc
	callab InitializeSpriteScreenPosition
	pop bc
.asm_fc783
	ld hl, wPikachuMovementStatus - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], $1
	ld hl, wPikachuWalkAnimationCounter - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], $0
	call RefreshPikachuFollow
	ret

Func_fc793: ; fc793 (3f:4793)
	call RefreshPikachuFollow
	push bc
	callab InitializeSpriteScreenPosition
	pop bc
	ld hl, wPikachuSpriteImageIdx - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], $ff
	dec hl
	ld [hl], $1
	ret

Func_fc7aa: ; fc7aa (3f:47aa)
	call Func_fcc92
	jp c, Func_fc803
	dec a
	ld l, a
	ld h, $0
	add hl, hl
	add hl, hl
	ld de, Pointer_fc7e3
	add hl, de
	ld d, h
	ld e, l
	ld a, [de]
	inc de
	ld hl, wPikachuFacingDirection - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], a
	ld a, [de]
	inc de
	ld hl, wPikachuXStepVector - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], a
	dec hl
	dec hl
	ld a, [de]
	ld [hl], a
	inc de
	ld a, [de]
	ld hl, wPikachuMovementStatus - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], a
	cp $4
	jp z, Func_fca0a
	call AreThereAtLeastTwoStepsInPikachuFollowCommandBuffer
	jp c, FastPikachuFollow
	jp NormalPikachuFollow

Pointer_fc7e3: ; fc7e3 (3f:47e3)
	db  0,  0
	db  1,  3
	db  4,  0
	db -1,  3
	db  8, -1
	db  0,  3
	db 12,  1
	db  0,  3
	db  0,  0
	db  1,  4
	db  4,  0
	db -1,  4
	db  8, -1
	db  0,  4
	db 12,  1
	db  0,  4

Func_fc803: ; fc803 (3f:4803)
	call Func_fcae2
	ret c
	ld hl, wPikachuWalkAnimationCounter - wPikachuSpriteStateData1
	add hl, bc
	dec [hl]
	jr nz, .asm_fc823
	push hl
	call GetPikachuFollowCommand
	pop hl
	cp $5
	jr nc, Func_fc842
	ld [hl], $20
	call Random
	and $c
	ld hl, wPikachuFacingDirection - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], a
.asm_fc823
	xor a
	ld hl, wPikachuIntraAnimFrameCounter - wPikachuSpriteStateData1
	add hl, bc
	ld [hli], a
	ld [hl], a
	call UpdatePikachuWalkingSprite
	ret

Func_fc82e: ; fc82e (3f:482e)
	ld a, [wWalkCounter]
	and a
	ret z
	scf
	ret

Func_fc835: ; fc835 (3f:4835)
	ld hl, wPikachuWalkAnimationCounter - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], $10
	ld hl, wPikachuMovementStatus - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], $1
	ret

Func_fc842: ; fc842 (3f:4842)
	ld hl, $0
	push af
	call Random
	ld a, [hRandomAdd]
	and %11
	ld e, a
	ld d, $0
	ld hl, PointerTable_fc85a
	add hl, de
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	pop af
	jp hl

PointerTable_fc85a: ; fc85a (3f:485a)
	dw Func_fc862
	dw Func_fc8f8
	dw Func_fc92b
	dw Func_fc95d

Func_fc862: ; fc862 (3f:4862)
	dec a
	add a
	add a
	and $c
	ld hl, wPikachuFacingDirection - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], a
	ld hl, wPikachuMovementStatus - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], $6
	xor a
	ld [wd432], a
	ld [wd433], a
	ld hl, wPikachuWalkAnimationCounter - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], $11
asm_fc87f: ; fc87f (3f:487f)
	ld a, [wd432]
	ld e, a
	ld a, [wd433]
	ld d, a
	call Func_fc82e
	jr c, Func_fc8c7
	call SetPikachuOverworldStateFlag2
	ld hl, wPikachuYPixels - wPikachuSpriteStateData1
	add hl, bc
	ld a, [hl]
	sub e
	ld e, a
	inc hl
	inc hl
	ld a, [hl]
	sub d
	ld d, a
	ld hl, wPikachuWalkAnimationCounter - wPikachuSpriteStateData1
	add hl, bc
	ld a, [hl]
	dec a
	add a
	add Pointer_fc8d6 % $100
	ld l, a
	ld a, Pointer_fc8d6 / $100
	adc $0
	ld h, a
	ld a, [hli]
	ld [wd432], a
	add e
	ld e, a
	ld a, [hl]
	ld [wd433], a
	add d
	ld d, a
	ld hl, wPikachuYPixels - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], e
	inc hl
	inc hl
	ld [hl], d
	ld hl, wPikachuWalkAnimationCounter - wPikachuSpriteStateData1
	add hl, bc
	dec [hl]
	ret nz
	jp Func_fc835

Func_fc8c7: ; fc8c7 (3f:48c7)
	ld hl, wPikachuYPixels - wPikachuSpriteStateData1
	add hl, bc
	ld a, [hl]
	sub e
	ld [hl], a
	inc hl
	inc hl
	ld a, [hl]
	sub d
	ld [hl], a
	jp Func_fc835

Pointer_fc8d6: ; fc8d6 (3f:48d6)
	db  0,  0
	db -2,  1
	db -4,  2
	db -2,  3
	db  0,  4
	db -2,  3
	db -4,  2
	db -2,  1
	db  0,  0
	db -2, -1
	db -4, -2
	db -2, -3
	db  0, -4
	db -2, -3
	db -4, -2
	db -2, -1
	db  0,  0

Func_fc8f8: ; fc8f8 (3f:48f8)
	ld hl, wPikachuMovementStatus - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], $7
	ld hl, wPikachuWalkAnimationCounter - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], $30
asm_fc904: ; fc904 (3f:4904)
	call Func_fc82e
	jp c, Func_fc835
	call SetPikachuOverworldStateFlag2
	ld hl, wPikachuIntraAnimFrameCounter - wPikachuSpriteStateData1
	add hl, bc
	ld a, [hl]
	inc a
	cp $8
	ld [hl], a
	jr nz, .asm_fc91f
	xor a
	ld [hli], a
	ld a, [hl]
	inc a
	and %11
	ld [hl], a
.asm_fc91f
	call UpdatePikachuWalkingSprite
	ld hl, wPikachuWalkAnimationCounter - wPikachuSpriteStateData1
	add hl, bc
	dec [hl]
	ret nz
	jp Func_fc835

Func_fc92b: ; fc92b (3f:492b)
	ld hl, wPikachuWalkAnimationCounter - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], $20
	ld hl, wPikachuMovementStatus - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], $8
asm_fc937: ; fc937 (3f:4937)
	call Func_fc82e
	jp c, Func_fc835
	call SetPikachuOverworldStateFlag2
	ld hl, wPikachuIntraAnimFrameCounter - wPikachuSpriteStateData1
	add hl, bc
	ld a, [hl]
	inc a
	cp $8
	ld [hl], a
	jr nz, .asm_fc951
	xor a
	ld [hli], a
	ld a, [hl]
	xor $1
	ld [hl], a
.asm_fc951
	call UpdatePikachuWalkingSprite
	ld hl, wPikachuWalkAnimationCounter - wPikachuSpriteStateData1
	add hl, bc
	dec [hl]
	ret nz
	jp Func_fc835

Func_fc95d: ; fc95d (3f:495d)
	ld hl, wPikachuWalkAnimationCounter - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], $20
	ld hl, wPikachuMovementStatus - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], $9
asm_fc969: ; fc969 (3f:4969)
	call Func_fc82e
	jp c, Func_fc835
	call SetPikachuOverworldStateFlag2
	ld hl, wPikachuIntraAnimFrameCounter - wPikachuSpriteStateData1
	add hl, bc
	ld a, [hl]
	inc a
	cp $8
	ld [hl], a
	jr nz, .asm_fc988
	xor a
	ld [hl], a
	ld hl, wPikachuFacingDirection - wPikachuSpriteStateData1
	add hl, bc
	ld a, [hl]
	call Func_fc994
	ld [hl], a
.asm_fc988
	call UpdatePikachuWalkingSprite
	ld hl, wPikachuWalkAnimationCounter - wPikachuSpriteStateData1
	add hl, bc
	dec [hl]
	ret nz
	jp Func_fc835

Func_fc994: ; fc994 (3f:4994)
	push hl
	ld hl, Pointer_fc9ac
	ld d, a
.loop
	ld a, [hli]
	cp d
	jr nz, .loop
	ld a, [hl]
	pop hl
	ret

Func_fc9a0: ; fc9a0 (3f:49a0)
	push hl
	ld hl, Pointer_fc9ac_End
	ld d, a
.loop
	ld a, [hld]
	cp d
	jr nz, .loop
	ld a, [hl]
	pop hl
	ret

Pointer_fc9ac: ; fc9ac (3f:49ac)
	db SPRITE_FACING_DOWN, SPRITE_FACING_LEFT, SPRITE_FACING_UP, SPRITE_FACING_RIGHT
	db SPRITE_FACING_DOWN, SPRITE_FACING_LEFT, SPRITE_FACING_UP, SPRITE_FACING_RIGHT
Pointer_fc9ac_End:

NormalPikachuFollow: ; fc9b4 (3f:49b4)
	ld hl, wPikachuWalkAnimationCounter - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], $8
	ld hl, wPikachuMovementStatus - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], $3
	call AddPikachuStepVector
asm_fc9c3: ; fc9c3 (3f:49c3)
	call TryDoubleAddPikachuStepVectorToScreenPixelCoords
	call GetPikachuWalkingAnimationSpeed
	call UpdatePikachuWalkingSprite
	ld hl, wPikachuWalkAnimationCounter - wPikachuSpriteStateData1
	add hl, bc
	dec [hl]
	ret nz
	call ResetPikachuStepVector
	call ComputePikachuFacingDirection
	ld hl, wPikachuMovementStatus - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], $1
	ret

FastPikachuFollow: ; fc9df (3f:49df)
	ld hl, wPikachuWalkAnimationCounter - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], $4
	ld hl, wPikachuMovementStatus - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], $5
	call AddPikachuStepVector
asm_fc9ee: ; fc9ee (3f:49ee)
	call DoubleAddPikachuStepVectorToScreenPixelCoords
	call GetPikachuWalkingAnimationSpeed
	call UpdatePikachuWalkingSprite
	ld hl, wPikachuWalkAnimationCounter - wPikachuSpriteStateData1
	add hl, bc
	dec [hl]
	ret nz
	call ResetPikachuStepVector
	call ComputePikachuFacingDirection
	ld hl, wPikachuMovementStatus - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], $1
	ret

Func_fca0a: ; fca0a (3f:4a0a)
	ld hl, wPikachuWalkAnimationCounter - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], $8
	ld hl, wPikachuMovementStatus - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], $4
	call AddPikachuStepVector
	call AddPikachuStepVector
asm_fca1c: ; fca1c (3f:4a1c)
	call DoubleAddPikachuStepVectorToScreenPixelCoords
	call GetPikachuWalkingAnimationSpeed
	call UpdatePikachuWalkingSprite
	ld hl, wPikachuWalkAnimationCounter - wPikachuSpriteStateData1
	add hl, bc
	dec [hl]
	ret nz
	call ResetPikachuStepVector
	call ComputePikachuFacingDirection
	ld hl, wPikachuMovementStatus - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], $1
	ret

AddPikachuStepVector: ; fca38 (3f:4a38)
	ld hl, wPikachuYStepVector - wPikachuSpriteStateData1
	add hl, bc
	ld e, [hl]
	inc hl
	inc hl
	ld d, [hl]
	ld hl, wPikachuMapY - wPikachuSpriteStateData1
	add hl, bc
	ld a, [hl]
	add e
	ld [hli], a
	ld a, [hl]
	add d
	ld [hl], a
	ret

TryDoubleAddPikachuStepVectorToScreenPixelCoords: ; fca4b (3f:4a4b)
	ld a, [wWalkBikeSurfState]
	cp $1 ; biking
	jr nz, AddPikachuStepVectorToScreenPixelCoords
	ld a, [wd736]
	bit 6, a
	jr nz, AddPikachuStepVectorToScreenPixelCoords
DoubleAddPikachuStepVectorToScreenPixelCoords: ; fca59 (3f:4a59)
	ld hl, wPikachuYStepVector - wPikachuSpriteStateData1
	add hl, bc
	ld a, [hli]
	add a
	add a
	add [hl]
	ld [hli], a
	ld a, [hli]
	add a
	add a
	add [hl]
	ld [hl], a
	ret

AddPikachuStepVectorToScreenPixelCoords: ; fca68 (3f:4a68)
	ld hl, wPikachuYStepVector - wPikachuSpriteStateData1
	add hl, bc
	ld a, [hli]
	add a
	add [hl]
	ld [hli], a
	ld a, [hli]
	add a
	add [hl]
	ld [hli], a
	ret

ResetPikachuStepVector: ; fca75 (3f:4a75)
	ld hl, wPikachuYStepVector - wPikachuSpriteStateData1
	add hl, bc
	xor a
	ld [hli], a
	inc hl
	ld [hl], a
	ret

GetPikachuWalkingAnimationSpeed: ; fca7e (3f:4a7e)
	call ComparePikachuHappinessTo80
	ld d, $2
	jr nc, .happy
	ld d, $5
.happy
	ld hl, wPikachuIntraAnimFrameCounter - wPikachuSpriteStateData1
	add hl, bc
	ld a, [hl]
	inc a
	cp d
	jr nz, .dont_reset
	xor a
.dont_reset
	ld [hli], a
	ret nz
	ld a, [hl]
	inc a
	and $3
	ld [hl], a
	ret

UpdatePikachuWalkingSprite: ; fca99 (3f:4a99)
	ld a, [wPikachuOverworldStateFlags]
	bit 3, a
	jr nz, .uninitialized
	ld hl, wPikachuSpriteImageBaseOffset - wPikachuSpriteStateData1
	add hl, bc
	ld a, [hl]
	dec a
	swap a
	ld d, a
	ld a, [wd736]
	bit 7, a
	jr nz, .copy_player
	ld hl, wPikachuFacingDirection - wPikachuSpriteStateData1
	add hl, bc
	ld a, [hl]
	or d
	ld d, a
	ld a, [wFontLoaded]
	bit 0, a
	jr z, .normal_get_sprite_index
	call Func_fcae2
	ret c
	jr .load_sprite_index

.normal_get_sprite_index
	ld hl, wPikachuAnimFrameCounter - wPikachuSpriteStateData1
	add hl, bc
	ld a, d
	or [hl]
	ld d, a
.load_sprite_index
	ld hl, wPikachuSpriteImageIdx - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], d
	ret

.uninitialized
	ld hl, wPikachuSpriteImageIdx - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], $ff
	ret

.copy_player
	ld a, [wPlayerSpriteImageIdx]
	and $f
	or d
	ld [wPikachuSpriteImageIdx], a
	ret

Func_fcae2: ; fcae2 (3f:4ae2)
	ld hl, wPikachuMapY - wPikachuSpriteStateData1
	add hl, bc
	ld a, [wYCoord]
	add $4
	cp [hl]
	jr nz, .on_screen
	inc hl
	ld a, [wXCoord]
	add $4
	cp [hl]
	jr nz, .on_screen
	ld hl, wPikachuSpriteImageIdx - wPikachuSpriteStateData1
	add hl, bc
	ld [hl], $ff
	scf
	ret

.on_screen
	and a
	ret

IsPikachuRightNextToPlayer: ; fcb01 (3f:4b01)
	push bc
	push de
	push hl
	ld bc, wPikachuPictureID
	ld a, [wXCoord]
	add $4
	ld d, a
	ld a, [wYCoord]
	add $4
	ld e, a
	ld hl, wPlayerMapY - wPlayerSpriteStateData1
	add hl, bc
	ld a, [hl]
	sub e
	and a
	jr z, .equal
	cp $ff
	jr z, .one_away
	cp $1
	jr z, .one_away
	jr .bad

.one_away
	ld hl, wPlayerMapX - wPlayerSpriteStateData1
	add hl, bc
	ld a, [hl]
	sub d
	jr z, .good
	jr .bad

.equal
	ld hl, wPlayerMapX - wPlayerSpriteStateData1
	add hl, bc
	ld a, [hl]
	sub d
	cp $ff
	jr z, .good
	cp $1
	jr z, .good
	and a
	jr z, .good
	jr .bad

.good
	pop hl
	pop de
	pop bc
	scf
	ret

.bad
	pop hl
	pop de
	pop bc
	xor a
	ret

GetPikachuFacingDirectionAndReturnToE: ; fcb4d (3f:4b4d)
	call GetPikachuFacingDirection
	ld e, a
	ret

GetPikachuFacingDirection: ; fcb52 (3f:4b52)
	ld bc, wPikachuPictureID
	ld a, [wXCoord]
	add $4
	ld d, a
	ld a, [wYCoord]
	add $4
	ld e, a
	ld hl, wPlayerMapY - wPlayerSpriteStateData1
	add hl, bc
	ld a, [hl]
	cp e
	jr z, .asm_fcb71
	jr nc, .asm_fcb6e
	ld a, SPRITE_FACING_UP
	ret

.asm_fcb6e
	ld a, SPRITE_FACING_DOWN
	ret

.asm_fcb71
	ld hl, wPlayerMapX - wPlayerSpriteStateData1
	add hl, bc
	ld a, [hl]
	cp d
	jr z, .asm_fcb81
	jr nc, .asm_fcb7e
	ld a, SPRITE_FACING_LEFT
	ret

.asm_fcb7e
	ld a, SPRITE_FACING_RIGHT
	ret

.asm_fcb81
	ld a, $ff ; standing
	ret

ClearPikachuFollowCommandBuffer: ; fcb84 (3f:4b84)
	push bc
	ld hl, wPikachuFollowCommandBufferSize
	ld [hl], $ff
	inc hl
	ld bc, $10
	xor a
	call FillMemory
	pop bc
	ret

AppendPikachuFollowCommandToBuffer: ; fcb94 (3f:4b94)
	ld hl, wPikachuFollowCommandBufferSize
	inc [hl]
	ld e, [hl]
	ld d, 0
	ld hl, wPikachuFollowCommandBuffer
	add hl, de
	ld [hl], a
	ret

RefreshPikachuFollow: ; fcba1 (3f:4ba1)
	call ClearPikachuFollowCommandBuffer
	call ComputePikachuFollowCommand
	ret c
	call AppendPikachuFollowCommandToBuffer
	ret

ComputePikachuFollowCommand: ; fcbac (3f:4bac)
	ld bc, wPikachuPictureID
	ld hl, wPlayerMapY - wPlayerSpriteStateData1
	add hl, bc
	ld a, [wYCoord]
	add $4
	sub [hl]
	jr z, .checkXCoord
	jr c, .pikaAbovePlayer
	call CheckAbsoluteValueLessThan2
	jr c, .return1
	ld a, $5
	and a
	ret

.return1
	ld a, $1
	and a
	ret

.pikaAbovePlayer
	call CheckAbsoluteValueLessThan2
	jr c, .return2
	ld a, $6
	and a
	ret

.return2
	ld a, $2
	and a
	ret

.checkXCoord
	ld hl, wPlayerMapX - wPlayerSpriteStateData1
	add hl, bc
	ld a, [wXCoord]
	add $4
	sub [hl]
	jr z, .pikachuOnTopOfPlayer
	jr c, .pikaToLeftOfPlayer
	call CheckAbsoluteValueLessThan2
	jr c, .return4
	ld a, $8
	and a
	ret

.return4
	ld a, $4
	and a
	ret

.pikaToLeftOfPlayer
	call CheckAbsoluteValueLessThan2
	jr c, .return3
	ld a, $7
	and a
	ret

.return3
	ld a, $3
	and a
	ret

.pikachuOnTopOfPlayer
	scf
	ret

CheckAbsoluteValueLessThan2: ; fcc01 (3f:4c01)
	jr nc, .positive
	cpl
	inc a
.positive
	cp $2
	ret

Func_fcc08:: ; fcc08 (3f:4c08)
	call Func_fcc23
	ret nc
	ld a, [wd736]
	bit 6, a
	jr nz, .asm_fcc1b
	call Func_fcc42
	ret c
	call AppendPikachuFollowCommandToBuffer
	ret

.asm_fcc1b
	call Func_fcc64
	ret c
	call AppendPikachuFollowCommandToBuffer
	ret

Func_fcc23: ; fcc23 (3f:4c28)
	ld a, [wPikachuOverworldStateFlags]
	bit 5, a
	jr nz, .asm_fcc40
	ld a, [wPikachuOverworldStateFlags]
	bit 7, a
	jr nz, .asm_fcc40
	ld a, [wd472]
	bit 7, a
	jr z, .asm_fcc40
	ld a, [wWalkBikeSurfState]
	and a
	jr nz, .asm_fcc40
	scf
	ret

.asm_fcc40
	and a
	ret

Func_fcc42: ; fcc42 (3f:4c42)
	xor a
	ld a, [wPlayerDirection]
	bit 3, a
	jr nz, .asm_fcc58
	bit 2, a
	jr nz, .asm_fcc5b
	bit 1, a
	jr nz, .asm_fcc5e
	bit 0, a
	jr nz, .asm_fcc61
	scf
	ret

.asm_fcc58
	ld a, $2
	ret

.asm_fcc5b
	ld a, $1
	ret

.asm_fcc5e
	ld a, $3
	ret

.asm_fcc61
	ld a, $4
	ret

Func_fcc64: ; fcc64 (3f:4c64)
	ld hl, wPikachuOverworldStateFlags
	bit 6, [hl]
	jr z, .asm_fcc6e
	res 6, [hl]
	ret

.asm_fcc6e
	set 6, [hl]
	xor a
	ld a, [wPlayerDirection]
	bit 3, a
	jr nz, .asm_fcc86
	bit 2, a
	jr nz, .asm_fcc89
	bit 1, a
	jr nz, .asm_fcc8c
	bit 0, a
	jr nz, .asm_fcc8f
	scf
	ret

.asm_fcc86
	ld a, $6
	ret

.asm_fcc89
	ld a, $5
	ret

.asm_fcc8c
	ld a, $7
	ret

.asm_fcc8f
	ld a, $8
	ret

Func_fcc92: ; fcc92 (3f:4c92)
	ld hl, wPikachuFollowCommandBufferSize
	ld a, [hl]
	cp $ff
	jr z, .asm_fccb0
	and a
	jr z, .asm_fccb0
	dec [hl]
	ld e, a
	ld d, 0
	ld hl, wPikachuFollowCommandBuffer
	add hl, de
	inc e
	ld a, $ff
.asm_fcca8
	ld d, [hl]
	ldd [hl], a
	ld a, d
	dec e
	jr nz, .asm_fcca8
	and a
	ret

.asm_fccb0
	scf
	ret

ComputePikachuFacingDirection:: ; fccb2 (3f:4cb2)
	call GetPikachuFollowCommandIfBufferSizeNonzero
	and a
	jr z, .check_y
	dec a
	and $3
	add a
	add a
	jr .load

.check_y
	ld a, [wYCoord]
	add $4
	ld d, a
	ld a, [wXCoord]
	add $4
	ld e, a
	ld a, [wPikachuMapY]
	cp d
	jr z, .check_x
	ld a, SPRITE_FACING_DOWN
	jr c, .load
	ld a, SPRITE_FACING_UP
	jr .load

.check_x
	ld a, [wPikachuMapX]
	cp e
	jr z, .copy_from_player
	ld a, SPRITE_FACING_RIGHT
	jr c, .load
	ld a, SPRITE_FACING_LEFT
	jr .load

.copy_from_player
	ld a, [wPlayerFacingDirection]
.load
	ld [wPikachuFacingDirection], a
	ret

GetPikachuFollowCommand: ; fccee (3f:4cee)
	ld hl, wPikachuFollowCommandBufferSize
	ld a, [hl]
	cp $ff
	jr z, .asm_fccff
	ld e, a
	ld d, 0
	ld hl, wPikachuFollowCommandBuffer
	add hl, de
	ld a, [hl]
	ret

.asm_fccff
	xor a
	ret

GetPikachuFollowCommandIfBufferSizeNonzero: ; fcd01 (3f:4d01)
	ld hl, wPikachuFollowCommandBufferSize
	ld a, [hl]
	cp $ff
	jr z, .default
	and a
	jr z, .default
	ld e, a
	ld d, 0
	ld hl, wPikachuFollowCommandBuffer
	add hl, de
	ld a, [hl]
	ret

.default
	xor a
	ret

AreThereAtLeastTwoStepsInPikachuFollowCommandBuffer: ; fcd17 (3f:4d17)
	ld a, [wPikachuFollowCommandBufferSize]
	cp $ff
	ret z
	cp $2
	jr nc, .set_carry
	and a
	ret

.set_carry
	scf
	ret

WillPikachuSpawnOnTheScreen: ; fcd25 (3f:4d25)
	ld h, wSpriteStateData2 / $100
	ld a, [H_CURRENTSPRITEOFFSET] ; If we're here, this can only be $f0
	add wPikachuMapY - wPikachuSpriteStateData2
	ld l, a
	ld b, [hl]
	ld a, [wYCoord]
	cp b
	jr z, .same_y
	jr nc, .not_on_screen
	add (SCREEN_HEIGHT / 2) - 1
	cp b
	jr c, .not_on_screen
.same_y
	inc l
	ld b, [hl]
	ld a, [wXCoord]
	cp b
	jr z, .same_x
	jr nc, .not_on_screen
	add (SCREEN_WIDTH / 2) - 1
	cp b
	jr c, .not_on_screen
.same_x
	call .GetNPCCurrentTile
	ld d, $60
	ld a, [hli]
	ld e, a
	cp d
	jr nc, .not_on_screen
	ld a, [hld]
	cp d
	jr nc, .not_on_screen
	ld bc, -20
	add hl, bc
	ld a, [hli]
	cp d
	jr nc, .not_on_screen
	ld a, [hl]
	cp d
	jr c, .on_screen
.not_on_screen
	ld h, wSpriteStateData1 / $100
	ld a, [H_CURRENTSPRITEOFFSET]
	add wPikachuSpriteImageIdx - wPikachuSpriteStateData1
	ld l, a
	ld [hl], $ff
	scf
	jr .return

.on_screen
	ld h, wSpriteStateData2 / $100
	ld a, [H_CURRENTSPRITEOFFSET]
	add wPikachuGrassPriority - wPikachuSpriteStateData2
	ld l, a
	ld a, [wGrassTile]
	cp e
	ld a, $0
	jr nz, .priority
	ld a, $80
.priority
	ld [hl], a
	and a
.return
	ret

.GetNPCCurrentTile: ; fcd83 (3f:4d83)
	ld h, wSpriteStateData1 / $100
	ld a, [H_CURRENTSPRITEOFFSET]
	add wPikachuYPixels - wPikachuSpriteStateData1
	ld l, a
	ld a, [hli]
	add $4
	and $f0
	srl a
	ld c, a
	ld b, $0
	inc l
	ld a, [hl]
	add $2
	srl a
	srl a
	srl a
	add SCREEN_WIDTH
	ld d, 0
	ld e, a
	ld hl, wTileMap
	rept 5
	add hl, bc
	endr
	add hl, de
	ret

ComparePikachuHappinessTo80: ; fcdad (3f:4dad)
; preserves a and bc
	push bc
	push af
	ld a, [wPikachuHappiness]
	cp 80
	pop bc
	ld a, b
	pop bc
	ret
