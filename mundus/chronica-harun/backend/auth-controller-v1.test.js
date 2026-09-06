const test = require('node:test');
const assert = require('node:assert/strict');
const {createAuthController} = require('./auth-controller-v1.js');

function makeBridge(){
  return {
    provider:null,
    flushes:0,
    clears:0,
    configureTokenProvider(fn){this.provider=fn;},
    clearTokenProvider(){this.provider=null;this.clears++;},
    async flush(){this.flushes++;}
  };
}

test('uses auth.token() when session object has no access_token', async () => {
  const bridge=makeBridge();
  const client={auth:{
    token: async()=>({data:{token:'jwt-from-token'},error:null}),
    getSession: async()=>({data:{session:{id:'s1'},user:{id:'u1'}},error:null}),
    signIn:{email:async()=>({data:{session:{id:'s1'},user:{id:'u1'}},error:null})},
    signUp:{email:async()=>({data:{session:{id:'s1'},user:{id:'u1'}},error:null})},
    signOut:async()=>({error:null})
  }};
  const controller=createAuthController({client,bridge});
  const state=await controller.refresh();
  assert.equal(state.authenticated,true);
  assert.equal(await bridge.provider(),'jwt-from-token');
});

test('falls back to getSession access_token when auth.token is unavailable', async()=>{
  const bridge=makeBridge();
  const client={auth:{
    getSession:async()=>({data:{session:{access_token:'legacy-jwt'},user:{id:'u1'}},error:null}),
    signIn:{email:async()=>({data:{session:{access_token:'legacy-jwt'},user:{id:'u1'}},error:null})},
    signUp:{email:async()=>({data:{session:{access_token:'legacy-jwt'},user:{id:'u1'}},error:null})},
    signOut:async()=>({error:null})
  }};
  const controller=createAuthController({client,bridge});
  await controller.refresh();
  assert.equal(await bridge.provider(),'legacy-jwt');
});

test('signIn authenticates when JWT comes only from auth.token()', async()=>{
  const bridge=makeBridge();
  const client={auth:{
    token:async()=>({data:{token:'signin-jwt'},error:null}),
    getSession:async()=>({data:{session:{id:'s2'},user:{id:'u2'}},error:null}),
    signIn:{email:async()=>({data:{session:{id:'s2'},user:{id:'u2'}},error:null})},
    signUp:{email:async()=>({data:null,error:null})},
    signOut:async()=>({error:null})
  }};
  const controller=createAuthController({client,bridge});
  const state=await controller.signIn('x@example.com','pw');
  assert.equal(state.authenticated,true);
  assert.equal(await bridge.provider(),'signin-jwt');
});

test('does not mark user authenticated when no JWT can be obtained', async()=>{
  const bridge=makeBridge();
  const client={auth:{
    token:async()=>({data:{token:null},error:null}),
    getSession:async()=>({data:{session:{id:'s3'},user:{id:'u3'}},error:null}),
    signIn:{email:async()=>({data:{session:{id:'s3'},user:{id:'u3'}},error:null})},
    signUp:{email:async()=>({data:null,error:null})},
    signOut:async()=>({error:null})
  }};
  const controller=createAuthController({client,bridge});
  const state=await controller.signIn('x@example.com','pw');
  assert.equal(state.authenticated,false);
  assert.equal(state.error,'Missing Neon Auth JWT');
  assert.equal(bridge.provider,null);
});
