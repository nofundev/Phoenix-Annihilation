return {
	armbeaver = {
		acceleration = 0.01842,
		brakerate = 0.03684,
		buildcostenergy = 3123,
		buildcostmetal = 150,
		builddistance = 112,
		builder = true,
		buildpic = "ARMBEAVER.DDS",
		buildtime = 6708,
		canmove = true,
		category = "ALL TANK PHIB NOTSUB CONSTR NOWEAPON NOTAIR NOTHOVER SURFACE",
		collisionvolumeoffsets = "0 0 0",
		collisionvolumescales = "34 22 41",
		collisionvolumetype = "Box",
		corpse = "DEAD",
		description = "Amphibious Construction Vehicle",
		energymake = 8,
		energyuse = 8,
		explodeas = "BIG_UNITEX",
		footprintx = 3,
		footprintz = 3,
		idleautoheal = 5,
		idletime = 1800,
		leavetracks = true,
		maxdamage = 925,
		maxslope = 16,
		maxvelocity = 1.3,
		maxwaterdepth = 255,
		metalmake = 0.08,
		metalstorage = 50,
		movementclass = "ATANK3",
		name = "Beaver",
		objectname = "ARMBEAVER",
		seismicsignature = 0,
		selfdestructas = "BIG_UNIT",
		sightdistance = 266,
		terraformspeed = 400,
		trackstrength = 5,
		tracktype = "StdTank",
		trackwidth = 31,
		turninplace = 1,
		turninplaceanglelimit = 60,
		turninplacespeedlimit = 0.9834,
		turnrate = 311,
		workertime = 80,
		buildoptions = {
			[1] = "armsolar",
			[2] = "armadvsol",
			[3] = "armwin",
			[4] = "armgeo",
			[5] = "armmstor",
			[6] = "armestor",
			[7] = "armmex",
			[8] = "armamex",
			[9] = "armmakr",
			[10] = "armlab",
			[11] = "armvp",
			[12] = "armap",
			[13] = "armhp",
			[14] = "armnanotc",
			[15] = "armeyes",
			[16] = "armrad",
			[17] = "armdrag",
			[18] = "armclaw",
			[19] = "armllt",
			[20] = "tawf001",
			[21] = "armhlt",
			[22] = "armguard",
			[23] = "armrl",
			[24] = "packo",
			[25] = "armcir",
			[26] = "armdl",
			[27] = "armjamt",
			[28] = "ajuno",
			[29] = "armfhp",
			[30] = "armsy",
			[31] = "armtide",
			[32] = "armuwmex",
			[33] = "armfmkr",
			[34] = "armuwms",
			[35] = "armuwes",
			[36] = "asubpen",
			[37] = "armsonar",
			[38] = "armfdrag",
			[39] = "armfrad",
			[40] = "armfhlt",
			[41] = "armfrt",
			[42] = "armptl",
		},
		featuredefs = {
			dead = {
				blocking = true,
				category = "corpses",
				collisionvolumeoffsets = "0.732467651367 -1.39770507808e-05 0.332275390625",
				collisionvolumescales = "34.8473205566 22.7869720459 36.573059082",
				collisionvolumetype = "Box",
				damage = 555,
				description = "Beaver Wreckage",
				energy = 0,
				featuredead = "HEAP",
				featurereclamate = "SMUDGE01",
				footprintx = 3,
				footprintz = 3,
				height = 20,
				hitdensity = 100,
				metal = 92,
				object = "ARMBEAVER_DEAD",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
			heap = {
				blocking = false,
				category = "heaps",
				collisionvolumescales = "55.0 4.0 6.0",
				collisionvolumetype = "cylY",
				damage = 278,
				description = "Beaver Heap",
				energy = 0,
				featurereclamate = "SMUDGE01",
				footprintx = 3,
				footprintz = 3,
				height = 4,
				hitdensity = 100,
				metal = 37,
				object = "3X3C",
				reclaimable = true,
				resurrectable = 0,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
		},
		sounds = {
			build = "nanlath1",
			canceldestruct = "cancel2",
			repair = "repair1",
			underattack = "warning1",
			working = "reclaim1",
			cant = {
				[1] = "cantdo4",
			},
			count = {
				[1] = "count6",
				[2] = "count5",
				[3] = "count4",
				[4] = "count3",
				[5] = "count2",
				[6] = "count1",
			},
			ok = {
				[1] = "varmmove",
			},
			select = {
				[1] = "varmsel",
			},
		},
	},
}
