class MovieMailer < ApplicationMailer
  def update_email
    mail(to: params[:email], subject: "#{params[:movie].title} updated")
  end
end
