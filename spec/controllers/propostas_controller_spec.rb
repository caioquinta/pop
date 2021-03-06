# -*- encoding : utf-8 -*-
require 'rails_helper'

describe PropostasController, type: :controller do
  describe 'listar' do

    context 'quando estiver logado' do
      before(:each) do
        @request.env["devise.mapping"] = Devise.mappings[:user]
        sign_in FactoryGirl.create(:user)
        get :index 
      end
      
      it 'o usuário pode acessar a lista de propostas' do
        response.should be_success
      end
    end
  end

  describe 'toppop' do
    let!(:user){ FactoryGirl.create(:user)}
    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:user]
	  sign_in user
    end

    context 'quando houver 10 ou mais propostas' do
      let!(:top10){ []}
      let!(:notop){ []}
      before(:each) do
        j = Proposta.maximum("votos_count").to_i 
	    for i in 1..10
          top10 << FactoryGirl.create( :proposta, :descricao => 'pop'<< i.to_s, :palavra_chave => 'pop')
          notop << FactoryGirl.create( :proposta, :descricao => 'notpop'<< i.to_s, :palavra_chave => 'nopop')
          j = j + 1
	      for i in 1..j
	        FactoryGirl.create( :voto, :proposta => top10.last)
          end
	    end
	    get :toppop
      end

      it 'as 10 propostas mais votadas do site devem aparecer' do
        expect(assigns(:list)-top10).to be_empty 
      end

      it 'exatamente 10 propostas devem aparecer' do
        expect(assigns(:list).count).to eq(10)
      end

      it 'propostas que não estão no top10 de votos do site não devem aparecer' do
        expect((assigns(:list)-notop).count).to eq(10)
      end

      it 'as propostas devem aparecer em ordem decrescente de votos' do
        expect(assigns(:list)).to eq(top10.reverse)
      end

      it 'o usuário pode acessar a lista de propostas mais apoiadas do pop' do
        response.should be_success
      end
      
    end
  end

  describe 'novasdasemana' do
    let!(:user){ FactoryGirl.create(:user)}
    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in user
    end

    context 'quando houver 10 ou mais propostas' do
      let!(:top10){ []}
      let!(:notop){ []}
      before(:each) do
        
        j = Proposta.maximum("votos_count").to_i 
      for i in 1..10
        notop << FactoryGirl.create( :proposta, :descricao => 'notpop'<< i.to_s, :palavra_chave => 'nopop')
      end
      for i in 1..10
        top10 << FactoryGirl.create( :proposta, :descricao => 'pop'<< i.to_s, :palavra_chave => 'pop')
        j = j + 1
        for i in 1..j
          FactoryGirl.create( :voto, :proposta => top10.last)
          end
      end
      get :novasdasemana
      end

      it 'as 10 propostas mais recentes do site devem aparecer' do
        expect(assigns(:list_semana) - top10).to be_empty
      end

      it 'exatamente 10 propostas devem aparecer' do
        expect(assigns(:list_semana).count).to eq(10)
      end

      it 'propostas que não estão no top10 de votos do site não devem aparecer' do
        expect((assigns(:list_semana)-notop).count).to eq(10)
      end

      it 'as propostas devem aparecer em ordem decrescente de votos' do
        expect(assigns(:list_semana)).to eq(top10.reverse)
      end

      it 'o usuário pode acessar a lista de propostas mais apoiadas do pop' do
        response.should be_success
      end

    end
  end

  describe 'lista meus apoios' do
    let!(:current_user) {FactoryGirl.create(:user)}

    before(:each) do
        @request.env["devise.mapping"] = Devise.mappings[:user]
        sign_in current_user
        get :meus_apoios 
    end
    it 'o usuário pode acessar a lista de propostas que ele apoiou' do
      response.should be_success
    end
  end

  describe 'lista top subprefeitura' do
    let!(:current_user) {FactoryGirl.create(:user)}

    before(:each) do
        @request.env["devise.mapping"] = Devise.mappings[:user]
        sign_in current_user
        get :top_subprefeitura
    end
    xit 'o usuário pode acessar a lista de propostas mais votadas da sua subprefeitura' do
      response.should be_success
    end
  end
  
  describe 'criar' do
    let!(:current_user){
      FactoryGirl.create(:user) 
    }
    let!(:proposta){
      FactoryGirl.build(:proposta)
    }
    let!(:proposta_params){
      {"descricao"=>"teste controller proposta","tema_principal_id"=>"1", "tema_opcional_id"=>"2", "palavra_chave"=>"key-word"}
    }
    let!(:acao){
      FactoryGirl.build(:acao)
    }
    let!(:voto){
      FactoryGirl.build(:voto)
    }
  
    before(:each) do
      Proposta.stubs(:create).with(proposta_params).returns(proposta)
      Acao.stubs(:create).returns(acao)
      Voto.stubs(:create).returns(voto)
      @request.env["devise.mapping"] = Devise.mappings[:user]
      sign_in current_user
    end

    context 'quando criar proposta' do
      before(:each) do
        post :create, proposta: proposta_params
      end
      it 'é esperado que o usuário seja redirecionado para a página de listagem de proposta' do
        is_expected.to redirect_to propostas_path
      end
    end

    context "quando o usuário atingir o limite de ações diário" do
      before(:each) do
        controller.stubs(:current_user).returns(current_user)
        current_user.stubs(:limite_acoes_atingido).returns(true)
        post :create, proposta: proposta_params
      end
      it 'deve aparecer uma mensagem de erro' do
        expect(flash[:warning]).to be_present
        flash[:warning].should eq("Proposta não foi criada. Limite de ações atingido!")
        is_expected.to redirect_to new_proposta_path
      end
    end

    context "quando a proposto tiver parâmetros errados" do
      let!(:proposta_params_invalid){
        {"descricao"=>nil,"tema_principal_id"=>"1", "tema_opcional_id"=>"2", "palavra_chave"=>"key-word"}
      }
      let!(:proposta_invalid){
        build(:proposta, proposta_params_invalid)
      }
      before(:each) do
        controller.stubs(:current_user).returns(current_user)
        current_user.stubs(:limite_acoes_atingido).returns(false)
        Proposta.stubs(:create).with(proposta_params_invalid).returns(proposta_invalid)
        post :create, proposta: proposta_params_invalid
      end
      it 'deve aparecer uma mensagem de erro' do
        expect(flash[:warning]).to be_present
        flash[:warning].should eq("Não foi possível criar proposta!")
        is_expected.to redirect_to new_proposta_path
      end
    end
  end

  describe 'nova' do
    let!(:proposta){ FactoryGirl.build(:proposta) }
    let!(:current_user){
      FactoryGirl.create(:user) 
    }
    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      sign_in current_user
    end
    context "quando o usuário estiver logado" do
      it 'o usuário pode acessar a página de criação de proposta' do
        get :new
        response.should be_success
      end
    end
    context "quando o usuário atingir o limite de ações diário" do
      it 'deve aparecer uma mensagem de erro' do
        controller.stubs(:current_user).returns(current_user)
        current_user.stubs(:limite_acoes_atingido).returns(true)
        get :new
        expect(flash[:warning]).to be_present
        flash[:warning].should eq("Limite de ações atingido!")
      end
    end
  end
end

