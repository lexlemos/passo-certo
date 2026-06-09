# Passo Certo

O **Passo Certeiro** é um instrumento de tecnologia assistiva aplicativo móvel destinado a promover autonomia, segurança e acessibilidade na mobilidade urbana e em espaços institucionais para pessoas com deficiência física e sensorial. 

Desenvolvido sob o ecossistema de inovação da Universidade Federal de Sergipe, o projeto centraliza rotas personalizadas e ferramentas adaptativas para navegação interna e externa.

---

## 🏗️ Arquitetura e Tecnologias

O projeto foi construído utilizando as melhores práticas de engenharia de software para garantir escalabilidade e independência de código:

* **Framework:** [Flutter](https://flutter.dev/) (Dart)
* **Padrão Arquitetural:** Clean Architecture (Isolamento de Camadas)
* **Abordagem de Design:** Domain-Driven Design (DDD) focado no domínio da acessibilidade.
* **Gerenciamento de Estado:** Riverpod

---

## 🚀 Como Executar o Projeto Localmente

### Pré-requisitos
Antes de começar, certifique-se de ter instalado em sua máquina:
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (Versão estável mais recente)
* [Dart SDK](https://dart.dev/get-dart)
* Emulador Android/iOS configurado ou um dispositivo físico conectado em modo de depuração.

### 1. Clonar o Repositório
Abra o terminal e clone a branch de desenvolvimento (`develop`):
\`\`\`bash
git clone -b develop https://github.com/SUA_ORGANIZACAO/passo-certeiro.git
cd passo-certeiro
\`\`\`

### 2. Instalar as Dependências
Execute o comando para baixar todos os pacotes do projeto:
\`\`\`bash
flutter pub get
\`\`\`

### 3. Executar o Aplicativo
Certifique-se de que há um emulador ativo ou dispositivo conectado executando `flutter devices`. Em seguida, rode:
\`\`\`bash
flutter run
\`\`\`

---

## 👥 Fluxo de Trabalho do Time (GitFlow)

Para manter o código organizado, siga as regras do repositório:

1. Nunca faça commits diretos na `main` ou na `develop`.
2. Para iniciar uma nova tarefa, crie uma branch a partir da `develop`:
   * `feature/nome-da-funcionalidade` (Para novos recursos)
   * `fix/ajuste-erro` (Para correção de bugs)
3. Ao finalizar, abra um **Pull Request (PR)** apontando para a branch `develop` e solicite a revisão do Diretor de Projetos.