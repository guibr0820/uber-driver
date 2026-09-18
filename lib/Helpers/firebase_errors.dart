String getErrorString(String code) {
  switch (code) {
    case 'weak-password':
      return 'Sua senha é muito fraca.';
    case 'invalid-email':
      return 'Seu e-mail é inválido.';
    case 'email-already-in-use':
      return 'E-mail já está sendo utilizado em outra conta.';
    case 'invalid-credential':
      return 'As credenciais fornecidas são inválidas. Verifique seu e-mail e senha.';
    case 'wrong-password':
      return 'Sua senha está incorreta.';
    case 'user-not-found':
      return 'Não há usuário com este e-mail. Verifique novamente.';
    case 'user-disabled':
      return 'Este usuário foi desabilitado.';
    case 'too-many-requests':
      return 'Muitas tentativas. Tente novamente mais tarde.';
    case 'operation-not-allowed':
      return 'Operação não permitida.';
    default:
      return 'Erro desconhecido. Tente novamente mais tarde.';
  }
}
