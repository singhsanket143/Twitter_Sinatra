require 'sinatra'
require 'data_mapper'



DataMapper.setup(:default, 'sqlite:///'+Dir.pwd+'/project.db')

class User
	include DataMapper::Resource
	property :id,	Serial
	property :username,	String,	:required => true
	property :password,	String,	:required => true
end

class Tweets
	include DataMapper::Resource
	property :id,	Serial
	property :tweet_message,	String, :required => true
	property :user_id,	Integer
	property :username,	String
end

class Likes
	include DataMapper::Resource
	property :id,	Serial
	property :user_id,	Integer
	property :tweet_id,	Integer
end

class Follow 
	include DataMapper::Resource
	property :id,	Serial
	property :user_id,	Integer
	property :follow_id,	Integer
end

DataMapper.finalize
DataMapper.auto_upgrade!
enable :sessions

get '/' do
	current_user=nil
	if session[:id]
		current_user=User.get(session[:id])
	else
		redirect '/login'
	end
	tweets=Tweets.all()
	likes=Likes.all()
	follow=Follow.all()
	users=User.all()
	erb :index , locals: {:tweets=>tweets , :current_user=>current_user , :likes=>likes, :follow=>follow,:users=>users}
end

get '/login' do
	erb :signin
end

get '/signup' do
	users=User.all()
	erb :signup 
end

post '/login' do
	username=params[:username]
	password=params[:password]
	user=User.all(:username=>username).first
	if user
		if user.password==password
			session[:id]=user.id
			redirect '/'
		else
			redirect 'login'
		end		
	else
		redirect '/signup'
	end
end


post '/logout' do
	session[:id]=nil
	return redirect '/'
end
post '/signup' do
	username=params[:username]
	password=params[:password]
	users=User.all
	users.each do |user|
		if user.username==username
			return redirect '/signup'
		end
	end
	new_user=User.new
	new_user.username=username
	new_user.password=password
	new_user.save
	session[:id]=new_user.id
	redirect '/'
end

post '/delete_account' do
	user=User.get(session[:id])
	tweets=Tweets.all(:user_id => session[:id])
	likes=Likes.all(:user_id => session[:id])
	tweets.destroy()
	user.destroy()
	likes.destroy()
	session[:id]=nil
	redirect '/'
end

post '/add' do
	tweet_message=params[:tweet_message]
	new_tweet=Tweets.new
	new_tweet.tweet_message=tweet_message
	new_tweet.user_id=session[:id]
	new_tweet.username=User.get(session[:id]).username
	new_tweet.save
	redirect '/'
end

post '/retweet' do
	retweet=Tweets.get(params[:retweet])
	new_tweet=Tweets.new
	new_tweet.tweet_message=retweet.tweet_message
	puts new_tweet.tweet_message
	new_tweet.user_id=session[:id]
	new_tweet.username=User.get(session[:id]).username
	new_tweet.save
	return redirect '/'

end

post '/delete_tweet' do
	tweet=Tweets.get(params[:delete])
	tweet.destroy()
	return redirect '/'
end

get '/follow/:follow_id' do
    follow=Follow.all(:follow_id=>params[:follow_id],:user_id=>session[:id]).first
    if !follow
		follow=Follow.new
		follow.follow_id=params[:follow_id]
		follow.user_id=session[:id]
		follow.save
	else
		follow.destroy
	end
    return redirect '/'
end
get '/like/:tweet_id' do
	like=Likes.all(:tweet_id=>params[:tweet_id],:user_id=>session[:id]).first
	if !like
		like=Likes.new
		like.tweet_id=params[:tweet_id]
		like.user_id=session[:id]
		like.save
	else
		like.destroy
	end
	redirect '/'
end

