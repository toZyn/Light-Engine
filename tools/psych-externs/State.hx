/**
 * Psych's `lua_State` handle. It only ever travels back into Psych, so on the
 * Lua target it is just the host table the engine hands in.
 */
typedef State = Dynamic;
