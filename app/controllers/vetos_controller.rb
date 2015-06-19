class VetosController < ApplicationController
  def new
  	@veto = Veto.new
  	@veto.proposta = Proposta.find_by_id(params[:proposta_id])
  end

  def create
  	@veto = Veto.create(veto_params)
		@veto.user_id = current_user.id
		if @veto.save
      @veto.proposta.desabilitar
			Acao.insere_acao( AcaoTipo.getVetar, @veto.proposta, current_user)
			insere_veto(@veto)
      mailer = PopMailer.avisar_veto(@veto.proposta, @veto)
      mailer.deliver
			redirect_to @veto	
		else
			flash[:warning] = "Não foi possível vetar a proposta!"
			redirect_to :action => 'new', :proposta_id => @veto.proposta_id
		end
  end

  def show
  	@veto = Veto.find_by_id(params[:id])

    unless @veto.present?
      render :text => 'Not Found', :status => '404'
    end
  end

  private
    def veto_params
      params.require(:veto).permit(:descricao, :proposta_id, :proposta)
    end

    def insere_veto( veto )	
    	Veto.create({
          user: current_user,
    	    descricao: veto.descricao,
    	    proposta: veto.proposta
    	})
    end
end
