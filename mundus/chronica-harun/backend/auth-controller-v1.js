(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  else root.CHRONICA_AUTH_CONTROLLER_FACTORY=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(){
  'use strict';
  function createAuthController({client,bridge,onState}){
    if(!client||!client.auth)throw new TypeError('client.auth is required');
    if(!bridge||typeof bridge.configureTokenProvider!=='function'||typeof bridge.clearTokenProvider!=='function')throw new TypeError('backend bridge is required');
    let current={authenticated:false,user:null,session:null,error:null,checkedAt:null};
    function emit(next){current=Object.freeze(Object.assign({},current,next||{},{checkedAt:new Date().toISOString()}));if(typeof onState==='function')try{onState(current)}catch(_){}return current;}
    async function tokenProvider(){
      if(typeof client.auth.token==='function'){
        const tokenResult=await client.auth.token();
        if(tokenResult&&tokenResult.error)throw new Error(tokenResult.error.message||'token_error');
        const raw=tokenResult&&tokenResult.data&&tokenResult.data.token;
        if(raw)return raw;
      }
      const result=await client.auth.getSession();
      if(result&&result.error)throw new Error(result.error.message||'session_error');
      const token=result&&result.data&&result.data.session&&result.data.session.access_token;
      if(!token)throw new Error('Missing Neon Auth JWT');
      return token;
    }
    async function applyAuth(data){
      const session=data&&data.session||null,user=data&&data.user||null;
      if(session&&user){
        try{
          await tokenProvider();
          bridge.configureTokenProvider(tokenProvider);
          if(typeof bridge.flush==='function')Promise.resolve(bridge.flush()).catch(()=>{});
          return emit({authenticated:true,user,session,error:null});
        }catch(error){
          bridge.clearTokenProvider();
          return emit({authenticated:false,user:null,session:null,error:error&&error.message?error.message:String(error)});
        }
      }
      bridge.clearTokenProvider();
      return emit({authenticated:false,user:null,session:null,error:null});
    }
    async function refresh(){try{const result=await client.auth.getSession();if(result&&result.error)throw new Error(result.error.message||'session_error');return await applyAuth(result&&result.data);}catch(error){bridge.clearTokenProvider();emit({authenticated:false,user:null,session:null,error:error&&error.message?error.message:String(error)});throw error;}}
    async function signIn(email,password){const result=await client.auth.signIn.email({email,password});if(result&&result.error)throw new Error(result.error.message||'sign_in_failed');return applyAuth(result&&result.data);}
    async function signUp(name,email,password){const result=await client.auth.signUp.email({name,email,password});if(result&&result.error)throw new Error(result.error.message||'sign_up_failed');return applyAuth(result&&result.data);}
    async function signOut(){const result=await client.auth.signOut();if(result&&result.error)throw new Error(result.error.message||'sign_out_failed');bridge.clearTokenProvider();return emit({authenticated:false,user:null,session:null,error:null});}
    return Object.freeze({refresh,signIn,signUp,signOut,tokenProvider,state:()=>current});
  }
  return {createAuthController};
});
