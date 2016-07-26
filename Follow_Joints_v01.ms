-----------------------------------------------------------------------------------------------------------------------------
-- This is a script that creates a simple FK rig that has joints that automaticly have follow through motion, 
-- By using script controllers and aim constraints all you do is animate the main control and the rest 
-- of the Joints follow. You can adjust the amout each joint delays and its amplatude on the indivudal controller
-- 
-- Usage- Double click the top joint chain and then run the script. Note depending on your scene scale the  
-- control objects might be really small or really large. 
--
-- Created by Andrez Aguayo 
-- 12/06/14
-- Email: andrez@aguayo.me
-- www.andrezaguayo.com
-- Please contact me with any questions, comments, bugs, or just want to chat. 
-----------------------------------------------------------------------------------------------------------------------------
function add_position_scriptController obj  =
(  --- This funcion addes a position list and postion script controller on the
    --- given object.
	
	-- create a Position List controller for the position controller
	obj.pos.controller = position_list()

	-- create a Position Script controller for the second Available position controller	& assign it
	ps = 	position_script()
	obj.pos.controller.Available.controller = ps
	
	return ps
)

function add_rotation_look_at_constraint obj  =
(  --- This funcion addes a rotation list and rotation script controller on the
    --- given object.
	
	-- create a Position List controller for the position controller
	obj.rotation.controller = rotation_list()

	-- create a Position Script controller for the second Available position controller	& assign it
	
	lc = 	lookat_constraint()
	obj.rotation.controller.Available.controller = lc
	
	return lc
)


function add_offset_attribute obj = 
(   --- This Function creats a custom atter Time_Offset that is added to an
	--- empty modifier called Time Offest.  
	
	--Create the defintion for the custom attribute 
	TimeOffsetAtter = attributes Time_Offset 
	( 
		--Parameter block to store the tracks of animation 
		parameters main rollout:params
		( 
			--A track of animation 
			--Look under scripted plugins for the types that can be used. 
			animationTrack type:#float UI:Time_Offset_Spinner Default:0.00
			springAmpTrack type:#float UI:spring_amp_Spinner Default:0.5
		) 

		--The rollout that will show up in the modifier panel. 
		rollout params "Custom Attributes" 
		( 
			--The spinner that is connected to the animationTrack 
			spinner Time_Offset_Spinner "Time_Offset"  range:[-200,200,0]
			spinner spring_amp_Spinner "Spring Amp"  range:[0,2,1]
		) 
	) 
	
	-- Make an empty Modifier to hold the attribute	
	eM=emptyModifier() 
	eM.Name = "Time_Offset"
	addModifier obj eM 
	--Add the Time Offset Atter. to the Modifier :) 
	custAttributes.add eM TimeOffsetAtter;
)



function script_controller_logic_tentacles obj MasterObject ps= 
(	--- This funciton builds the logic for the script controller that causes the delay to work---   
	
	-- Assign a Node Variable to Script Controller: Master Box Transform Position
	ps.addNode "Master_Box" MasterObject

	-- Assign a Track Variable to the Script Controller: The objects "Time Offset" Atter.
	ps.addTarget "OffsetVal" MasterObject[#Modified_Object][#Time_Offset].Time_Offset[#animationTrack]
	ps.addTarget "amp" MasterObject[#Modified_Object][#Time_Offset].Time_Offset[#springAmpTrack]
	
	--  Create the expression string
	thePosExpression = "if Master_Box != undefined then\n"
	thePosExpression += "(\n"
	thePosExpression += "offsetValue = at time(currentTime - OffsetVal) Master_Box.position\n"
	thePosExpression += ("finalPos = offsetValue - " + MasterObject.position as string +"\n")
	thePosExpression += "amp = amp - 1\n" 
	thePosExpression += "differenceVector = offsetValue - Master_Box.position\n"
	thePosExpression += "diffScaled = differenceVector * amp\n"
	thePosExpression += "finalPos = finalPos + diffScaled \n" 
	thePosExpression += "finalPos\n" 
	
	thePosExpression += ")\n"
	thePosExpression += "else\n"
	thePosExpression += "(\n"
	thePosExpression += "[0,0,0]\n"
	thePosExpression += ")"
	-- thePosExpression
	ps.SetExpression (thePosExpression)	

)

function make_follow_through_rig = 
(	--- This is the main funcion that builds the rig  ---   
	mySel = getcurrentselection()
	parentBox = false 	
	masterBox = "" 	
	for i in 1 to mySel.count  do 
	(	-- for i in bones 	
		if classof mySel[i] ==  BoneGeometry then 
		(	---- make point helpers
			---- one cross 
			
			if i == 1 then 
			(
				masterBox = point cross:on box:on centermarker:off size:5 name:(mySel[i].name +"_MASTER") wirecolor:red
				masterBox.rotation = mySel[i].rotation
				masterBox.pos = mySel[i].pos
				mySel[i].parent = masterBox
				parentBox = masterBox						
			)
			
			else 
			(
				myPoint = point cross:off box:off centermarker:off size:5 name:(mySel[i].name +"_Cross") wirecolor:blue
				myPoint.rotation = mySel[i].rotation	
				myPoint.pos = mySel[i].pos
				---- one box 
				myBox = point cross:off box:on centermarker:off size:5 name:(mySel[i].name +"_Box") wirecolor:green
				myBox.rotation = mySel[i].rotation
				myBox.pos = mySel[i].pos
				
				myTarget = point cross:off box:off centermarker:on size:5 name:(mySel[i].name +"_Target") wirecolor:yellow
				myTarget.rotation = mySel[i].rotation
				myTarget.pos = mySel[i].pos
				
				
				---- link boxes on to eacchother 
				if classof parentBox != UndefinedClass do
				(	myBox.parent = parentBox
				)
				
				---- link crosses on to bone below if it is the first time making a cross aka on the second bone then link it to the master box 
				if i == 2 then 
				(
					myPoint.parent = parentBox
				)		
				else 
				(	
					myPoint.parent = mySel[i-2]
				)
				
				--- add rotation list to Bone and add a look at controller to the rotation 
				lc = add_rotation_look_at_constraint mySel[i-1]
				--- add target 
				lc.appendTarget myTarget 100
				-- look at axis is X--- X:0 Y:2 Z:3
				lc.target_axis = 0
				lc.upnode_world = off
				lc.pickUpNode = myPoint
				lc.viewline_length_abs = off
				lc.lookat_vector_length = 0

				parentBox = myBox
				
				add_offset_attribute myBox
				ps = add_position_scriptController myTarget
				script_controller_logic_tentacles myTarget myBox ps
				
				myBox.modifiers[#Time_Offset].Time_Offset.animationTrack = (i)
				
				--cS
			)
		)
	)
	return masterBox
)


make_follow_through_rig()