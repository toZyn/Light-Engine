local os = (require "love.system").getOS()

return {
	DEBUG_MODE = false,

	title = "Light Engine",
	file = "Light Engine",
	icon = "art/icon.png",
	version = "0.1.0",
	package = "com.zyn.lightengine"
	width = 1280,
	height = 720,

	adaptableWidth = os == "Android" or os == "iOS",

	FPS = 60,
	vSync = true,
	company = "Zyn",

	flags = {
		checkForUpdates = false,

		loxelInitialAutoPause = true,
		loxelInitialParallelUpdate = true,
		loxelInitialAsyncInput = false,

		loxelForceRenderCameraComplex = false,
		loxelDisableRenderCameraComplex = false,
		loxelDisableScissorOnRenderCameraSimple = false,
		loxelDefaultClipCamera = true
	}
}
